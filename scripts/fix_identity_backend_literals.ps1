function Replace-Regex {
    param(
        [string]$Path,
        [string]$Pattern,
        [string]$Replacement
    )

    $content = Get-Content -Raw $Path
    if (-not [regex]::IsMatch($content, $Pattern)) {
        throw "Regex block not found in $Path"
    }

    $updated = [regex]::Replace($content, $Pattern, $Replacement, 1)
    Set-Content -Path $Path -Value $updated -Encoding utf8
}

$trustSafetyService = 'C:\Users\PC SOFT\Desktop\jord\src\modules\trust-safety\trust-safety.service.ts'
$adminService = 'C:\Users\PC SOFT\Desktop\jord\src\modules\admin\admin.service.ts'

Replace-Regex -Path $trustSafetyService -Pattern "(?s)async uploadIdDocument\(.*?\n    \}\n\n    async uploadMarriageCert" -Replacement @'
async uploadIdDocument(
        userId: string,
        file: Express.Multer.File,
        documentType?: string,
    ) {
        if (!file) throw new BadRequestException('No document file provided');

        const allowedDocumentTypes = ['passport', 'national_id', 'driving_license'];
        const normalizedDocumentType = allowedDocumentTypes.includes(documentType || '')
            ? documentType!
            : 'national_id';

        const result = await this.cloudinaryService.uploadImage(file);
        await this.userRepository.update(userId, {
            documentUrl: result.secure_url,
            documentType: normalizedDocumentType,
            documentVerified: false,
            documentVerifiedAt: null,
            documentRejectionReason: null,
        } as any);

        await this.redisService.set(`id_doc:${userId}`, result.secure_url, 0);
        await this.redisService.set(this.idDocumentStatusKey(userId), 'pending_review');

        await this.contentFlagRepository.save({
            userId,
            type: ContentFlagType.OTHER,
            status: ContentFlagStatus.PENDING,
            source: ContentFlagSource.USER_REPORT,
            content: `Identity document (${normalizedDocumentType}) uploaded for verification: ${result.secure_url}`,
            entityType: 'verification',
            entityId: userId,
            confidenceScore: 1.0,
        });

        this.logger.log(`Identity document uploaded for user ${userId} (${normalizedDocumentType})`);
        return {
            message: 'Identity document uploaded. It will be reviewed by our team within 24-48 hours.',
            status: 'pending_review',
            documentType: normalizedDocumentType,
            documentUrl: result.secure_url,
        };
    }

    async uploadMarriageCert
'@

Replace-Regex -Path $trustSafetyService -Pattern "(?s)async getVerificationStatus\(userId: string\) \{.*?\n    \}\n\n    //" -Replacement @'
async getVerificationStatus(userId: string) {
        const user = await this.userRepository.findOne({
            where: { id: userId },
            select: [
                'id',
                'selfieVerified',
                'emailVerified',
                'selfieUrl',
                'trustScore',
                'documentVerified',
                'documentUrl',
                'documentType',
                'documentVerifiedAt',
                'documentRejectionReason',
            ],
        });

        const idDocUrl = await this.redisService.get(`id_doc:${userId}`);
        const marriageCertUrl = await this.redisService.get(`marriage_cert:${userId}`);
        const selfieStatus = user?.selfieVerified
            ? 'verified'
            : (await this.redisService.get(this.selfieStatusKey(userId))) ||
              (user?.selfieUrl ? 'uploaded' : 'not_uploaded');
        const idDocumentStatus = user?.documentVerified
            ? 'verified'
            : (await this.redisService.get(this.idDocumentStatusKey(userId))) ||
              (user?.documentRejectionReason
                  ? 'reverify_required'
                  : ((idDocUrl || user?.documentUrl) ? 'pending_review' : 'not_uploaded'));
        const marriageCertStatus =
            (await this.redisService.get(this.marriageCertStatusKey(userId))) ||
            (marriageCertUrl ? 'pending_review' : 'not_uploaded');

        return {
            emailVerified: user?.emailVerified ?? false,
            selfieVerified: user?.selfieVerified ?? false,
            selfieUploaded: !!user?.selfieUrl,
            selfieStatus,
            idDocumentUploaded: !!(idDocUrl || user?.documentUrl),
            idDocumentStatus,
            documentUrl: user?.documentUrl || idDocUrl || null,
            documentType: user?.documentType || null,
            documentVerified: user?.documentVerified ?? false,
            documentVerifiedAt: user?.documentVerifiedAt ?? null,
            documentRejectionReason: user?.documentRejectionReason || null,
            marriageCertUploaded: !!marriageCertUrl,
            marriageCertStatus,
            trustScore: user?.trustScore ?? 100,
        };
    }

    //
'@

Replace-Regex -Path $adminService -Pattern "(?s)async verifyDocument\(userId: string, approved: boolean, rejectionReason\?: string\)\s*\{.*?\}\s*async autoApproveDocuments" -Replacement @'
async verifyDocument(userId: string, approved: boolean, rejectionReason?: string) {
        const user = await this.userRepository.findOne({ where: { id: userId } });
        if (!user) throw new NotFoundException('User not found');
        if (!user.documentUrl) throw new BadRequestException('User has no document uploaded');

        user.documentVerified = approved;
        user.documentVerifiedAt = approved ? new Date() : null;
        (user as any).documentRejectionReason = approved
            ? null
            : (rejectionReason || 'Please upload a clearer passport, national ID, or driver''s license.');

        if (approved && user.status === UserStatus.PENDING_VERIFICATION) {
            user.status = UserStatus.ACTIVE;
        }

        const savedUser = await this.userRepository.save(user);
        await this.redisService.set(
            `id_doc_status:${userId}`,
            approved ? 'verified' : 'reverify_required',
            0,
        );

        await this.notificationRepository.save(
            this.notificationRepository.create({
                userId,
                type: NotificationType.VERIFICATION,
                title: approved ? 'Identity verified' : 'Reverify your identity',
                body: approved
                    ? 'Your identity document has been approved by the Methna team.'
                    : (rejectionReason || 'Please re-upload a valid passport, national ID, or driver''s license.'),
                data: {
                    status: approved ? 'verified' : 'reverify_required',
                    documentType: user.documentType ?? null,
                    rejectionReason: approved ? null : (rejectionReason || null),
                },
            }),
        );

        this.logger.log(`Admin ${approved ? 'approved' : 'requested reverify for'} identity document of user ${userId}`);
        return savedUser;
    }

    async autoApproveDocuments
'@

Replace-Regex -Path $adminService -Pattern "(?s)async autoApproveDocuments\(\)\s*\{.*?\}\s*//" -Replacement @'
async autoApproveDocuments() {
        const pending = await this.userRepository.find({
            where: { documentUrl: Not(IsNull()), documentVerified: false },
        });
        let count = 0;
        for (const user of pending) {
            user.documentVerified = true;
            user.documentVerifiedAt = new Date();
            (user as any).documentRejectionReason = null;
            if (user.status === UserStatus.PENDING_VERIFICATION) {
                user.status = UserStatus.ACTIVE;
            }
            await this.userRepository.save(user);
            await this.redisService.set(`id_doc_status:${user.id}`, 'verified', 0);
            count++;
        }
        this.logger.log(`Auto-approved ${count} pending documents`);
        return { approved: count };
    }

    //
'@
