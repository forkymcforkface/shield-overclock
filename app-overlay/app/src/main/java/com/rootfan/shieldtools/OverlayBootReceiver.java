package com.rootfan.shieldtools;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public final class OverlayBootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent == null ? null : intent.getAction();
        if (!Intent.ACTION_BOOT_COMPLETED.equals(action) && !"android.intent.action.QUICKBOOT_POWERON".equals(action)) return;
        PendingResult pending = goAsync();
        new Thread(() -> {
            try {
                Thread.sleep(5000);
                int mode = context.getSharedPreferences("overlay", Context.MODE_PRIVATE).getInt("fan_mode", 0);
                if (mode == 0) RootOps.run("echo 1 > /sys/devices/pwm-fan/temp_control");
                else RootOps.run("echo 255 > /sys/devices/pwm-fan/target_pwm; echo 0 > /sys/devices/pwm-fan/temp_control");
            } catch (Exception ignored) {
            } finally {
                pending.finish();
            }
        }).start();
    }
}
