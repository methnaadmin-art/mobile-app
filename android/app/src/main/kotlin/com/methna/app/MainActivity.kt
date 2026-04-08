package com.methna.app

import android.os.Bundle
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ensureGooglePlayServices()
    }

    override fun onResume() {
        super.onResume()
        ensureGooglePlayServices()
    }

    private fun ensureGooglePlayServices() {
        val availability = GoogleApiAvailability.getInstance()
        val status = availability.isGooglePlayServicesAvailable(this)
        if (status != ConnectionResult.SUCCESS) {
            availability.makeGooglePlayServicesAvailable(this)
        }
    }
}
