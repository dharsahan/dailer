package com.example.flutter_dialer

import android.content.Intent
import android.telecom.Call
import android.telecom.InCallService
import android.util.Log

class CallService : InCallService() {
    companion object {
        var callListener: ((Call, Int) -> Unit)? = null
        const val STATE_CONNECTING = 9
        const val STATE_DIALING = 1
        const val STATE_RINGING = 2
        const val STATE_ACTIVE = 4
        const val STATE_DISCONNECTED = 7
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        Log.d("CallService", "onCallAdded: $call")
        updateCallState(call, call.state)
        call.registerCallback(object : Call.Callback() {
            override fun onStateChanged(call: Call, state: Int) {
                super.onStateChanged(call, state)
                Log.d("CallService", "onStateChanged: $state")
                updateCallState(call, state)
            }
        })
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        Log.d("CallService", "onCallRemoved")
        updateCallState(call, STATE_DISCONNECTED)
    }

    private fun updateCallState(call: Call, state: Int) {
        // Send updates to MainActivity or broadcast
        callListener?.invoke(call, state)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return super.onStartCommand(intent, flags, startId)
    }
}
