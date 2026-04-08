function Replace-Exact {
    param(
        [string]$Path,
        [string]$Old,
        [string]$New
    )

    $content = Get-Content -Raw $Path
    if (-not $content.Contains($Old)) {
        throw "Exact block not found in $Path"
    }

    $content = $content.Replace($Old, $New)
    Set-Content -Path $Path -Value $content -Encoding utf8
}

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

$trustSafetyController = 'C:\Users\PC SOFT\Desktop\jord\src\modules\trust-safety\trust-safety.controller.ts'
$trustSafetyService = 'C:\Users\PC SOFT\Desktop\jord\src\modules\trust-safety\trust-safety.service.ts'
$adminService = 'C:\Users\PC SOFT\Desktop\jord\src\modules\admin\admin.service.ts'
$adminController = 'C:\Users\PC SOFT\Desktop\jord\src\modules\admin\admin.controller.ts'

@"
import {
    Controller,
    Get,
    Post,
    Patch,
    Param,
    Query,
    Body,
    UseGuards,
    UseInterceptors,
    UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiConsumes, ApiBody } from '@nestjs/swagger';
import { TrustSafetyService } from './trust-safety.service';
import { BackgroundCheckService } from './background-check.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { UserRole } from '../../database/entities/user.entity';
import { ContentFlagStatus } from '../../database/entities/content-flag.entity';

@ApiTags('trust-safety')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('trust-safety')
export class TrustSafetyController {
    constructor(
        private readonly trustSafetyService: TrustSafetyService,
        private readonly backgroundCheckService: BackgroundCheckService,
    ) { }

    // Selfie Upload + Verify
    @Post('selfie-upload')
    @UseInterceptors(FileInterceptor('selfie'))
    @ApiConsumes('multipart/form-data')
    @ApiBody({
        schema: {
            type: 'object',
            properties: {
                selfie: { type: 'string', format: 'binary' },
            },
        },
    })
    @ApiOperation({ summary: 'Upload a selfie for verification' })
    async uploadSelfie(
        @CurrentUser('sub') userId: string,
        @UploadedFile() file: Express.Multer.File,
    ) {
        return this.trustSafetyService.uploadSelfie(userId, file);
    }

    @Post('selfie-verify')
    @ApiOperation({ summary: 'Submit selfie verification for automated or manual review' })
    async verifySelfie(@CurrentUser('sub') userId: string) {
        return this.trustSafetyService.compareSelfieToPhotos(userId);
    }

    // Identity Document Upload
    @Post('id-upload')
    @UseInterceptors(FileInterceptor('document'))
    @ApiConsumes('multipart/form-data')
    @ApiBody({
        schema: {
            type: 'object',
            properties: {
                document: { type: 'string', format: 'binary' },
                documentType: {
                    type: 'string',
                    enum: ['passport', 'national_id', 'driving_license'],
                },
            },
        },
    })
    @ApiOperation({ summary: 'Upload an identity document for manual verification' })
    async uploadIdDocument(
        @CurrentUser('sub') userId: string,
        @UploadedFile() file: Express.Multer.File,
        @Body() body: { documentType?: string },
    ) {
        return this.trustSafetyService.uploadIdDocument(
            userId,
            file,
            body?.documentType,
        );
    }

    // Marriage Certificate Upload
    @Post('marriage-cert-upload')
    @UseInterceptors(FileInterceptor('certificate'))
    @ApiConsumes('multipart/form-data')
    @ApiBody({
        schema: {
            type: 'object',
            properties: {
                certificate: { type: 'string', format: 'binary' },
            },
        },
    })
    @ApiOperation({ summary: 'Upload a marriage certificate for verification' })
    async uploadMarriageCert(
        @CurrentUser('sub') userId: string,
        @UploadedFile() file: Express.Multer.File,
    ) {
        return this.trustSafetyService.uploadMarriageCert(userId, file);
    }

    // Verification Status
    @Get('verification-status')
    @ApiOperation({ summary: 'Get current verification status of user' })
    async getVerificationStatus(@CurrentUser('sub') userId: string) {
        return this.trustSafetyService.getVerificationStatus(userId);
    }

    @Get('trust-score')
    @ApiOperation({ summary: 'Get your trust score' })
    async getTrustScore(@CurrentUser('sub') userId: string) {
        const score = await this.trustSafetyService.getTrustScore(userId);
        return { trustScore: score };
    }

    // Admin endpoints
    @Get('admin/flags')
    @UseGuards(RolesGuard)
    @Roles(UserRole.ADMIN)
    @ApiOperation({ summary: 'Get pending content flags (admin)' })
    async getPendingFlags(
        @Query('page') page?: number,
        @Query('limit') limit?: number,
    ) {
        return this.trustSafetyService.getPendingFlags(page || 1, limit || 20);
    }

    @Patch('admin/flags/:id')
    @UseGuards(RolesGuard)
    @Roles(UserRole.ADMIN)
    @ApiOperation({ summary: 'Resolve a content flag (admin)' })
    async resolveFlag(
        @CurrentUser('sub') adminId: string,
        @Param('id') flagId: string,
        @Body() body: { status: ContentFlagStatus; note?: string },
    ) {
        await this.trustSafetyService.resolveFlag(flagId, adminId, body.status, body.note);
        return { message: 'Flag resolved' };
    }

    @Post('admin/shadow-ban/:userId')
    @UseGuards(RolesGuard)
    @Roles(UserRole.ADMIN)
    @ApiOperation({ summary: 'Shadow ban a user (admin)' })
    async shadowBan(@Param('userId') userId: string) {
        await this.trustSafetyService.shadowBanUser(userId);
        return { message: 'User shadow banned' };
    }

    @Post('admin/remove-shadow-ban/:userId')
    @UseGuards(RolesGuard)
    @Roles(UserRole.ADMIN)
    @ApiOperation({ summary: 'Remove shadow ban (admin)' })
    async removeShadowBan(@Param('userId') userId: string) {
        await this.trustSafetyService.removeShadowBan(userId);
        return { message: 'Shadow ban removed' };
    }

    @Post('admin/detect-suspicious/:userId')
    @UseGuards(RolesGuard)
    @Roles(UserRole.ADMIN)
    @ApiOperation({ summary: 'Run suspicious behavior detection on a user (admin)' })
    async detectSuspicious(@Param('userId') userId: string) {
        return this.trustSafetyService.detectSuspiciousBehavior(userId);
    }

    // Background check
    @Post('background-check')
    @ApiOperation({ summary: 'Initiate a background check (requires consent)' })
    async initiateBackgroundCheck(
        @CurrentUser('sub') userId: string,
        @Body() body: { fullName: string; dateOfBirth: string; consentGiven: boolean },
    ) {
        return this.backgroundCheckService.initiateCheck(userId, body);
    }

    @Get('background-check')
    @ApiOperation({ summary: 'Get background check status' })
    async getBackgroundCheckStatus(@CurrentUser('sub') userId: string) {
        return this.backgroundCheckService.getCheckStatus(userId);
    }

    @Post('background-check/webhook')
    @ApiOperation({ summary: 'Handle background check provider webhook' })
    async backgroundCheckWebhook(@Body() payload: any) {
        await this.backgroundCheckService.handleWebhook(payload);
        return { received: true };
    }
}
"@ | Set-Content -Path $trustSafetyController -Encoding utf8

Replace-Regex -Path $trustSafetyService -Pattern "(?s)async uploadIdDocument\(.*?\n    \}\n\n    async uploadMarriageCert" -Replacement @"
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
"@

Replace-Regex -Path $trustSafetyService -Pattern "(?s)async getVerificationStatus\(userId: string\) \{.*?\n    \}\n\n    //" -Replacement @"
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
"@

$trustSafetyServiceContent = Get-Content -Raw $trustSafetyService
if ($trustSafetyServiceContent.Contains("approved ? 'verified' : 'rejected'")) {
    $trustSafetyServiceContent = $trustSafetyServiceContent.Replace(
        "approved ? 'verified' : 'rejected'",
        "approved ? 'verified' : 'reverify_required'"
    )
    Set-Content -Path $trustSafetyService -Value $trustSafetyServiceContent -Encoding utf8
}

$adminServiceContent = Get-Content -Raw $adminService
if (-not $adminServiceContent.Contains("import { RedisService } from '../redis/redis.service';")) {
    $adminServiceContent = $adminServiceContent.Replace(
        "import { PaginationDto } from '../../common/dto/pagination.dto';",
        "import { PaginationDto } from '../../common/dto/pagination.dto';`r`nimport { RedisService } from '../redis/redis.service';"
    )
}
$adminServiceContent = $adminServiceContent.Replace(
    "        @InjectRepository(Plan)`r`n        private readonly planRepository: Repository<Plan>,`r`n    ) { }",
    "        @InjectRepository(Plan)`r`n        private readonly planRepository: Repository<Plan>,`r`n        private readonly redisService: RedisService,`r`n    ) { }"
)
Set-Content -Path $adminService -Value $adminServiceContent -Encoding utf8

Replace-Regex -Path $adminService -Pattern "(?s)async getPendingDocuments\(\)\s*\{.*?\}\s*async verifyDocument" -Replacement @"
async getPendingDocuments() {
        return this.userRepository.find({
            where: {
                documentUrl: Not(IsNull()),
                documentVerified: false,
                documentRejectionReason: IsNull(),
            },
            order: { createdAt: 'DESC' },
        });
    }

    async verifyDocument
"@

Replace-Regex -Path $adminService -Pattern "(?s)async verifyDocument\(userId: string, approved: boolean, rejectionReason\?: string\)\s*\{.*?\}\s*async autoApproveDocuments" -Replacement @"
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
"@

Replace-Regex -Path $adminService -Pattern "(?s)async autoApproveDocuments\(\)\s*\{.*?\}\s*//" -Replacement @"
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
"@

Replace-Exact -Path $adminController -Old "action: dto.approved ? 'approve_document' : 'reject_document'," -New "action: dto.approved ? 'approve_document' : 'request_document_reverify',"
