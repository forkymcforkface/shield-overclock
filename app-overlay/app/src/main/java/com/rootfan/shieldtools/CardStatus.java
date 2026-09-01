package com.rootfan.shieldtools;

import android.content.Context;

import java.util.Locale;

public final class CardStatus {
    public static String get(Context context, String title) {
        try {
            if ("CPU".equals(title)) return mhz(RootOps.readLong("/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq"), 1000.0);
            if ("GPU".equals(title)) return mhz(RootOps.readLong("/sys/devices/57000000.gpu/devfreq/57000000.gpu/max_freq"), 1000000.0);
            if ("RAM".equals(title)) return mhz(RootOps.readLong("/sys/kernel/debug/tegra_bwmgr/debug_client_cap"), 1000000.0);
            if ("Governor".equals(title)) return RootOps.read("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor");
            if ("Fan".equals(title)) return RootOps.readLong("/sys/devices/pwm-fan/temp_control") == 1 ? "Auto" : "Max cooling";
            if ("Trackpad Speed".equals(title)) return optional("/sys/module/hid_nvidia_blake/parameters/speed");
            if ("Mouse Button".equals(title)) return mouse(optional("/sys/module/hid_nvidia_blake/parameters/mouseClickButton"));
        } catch (Exception ignored) {
        }
        return "Unavailable";
    }

    private static String mhz(long value, double divisor) {
        return String.format(Locale.US, "%.1f MHz", value / divisor);
    }

    private static String optional(String path) throws Exception {
        String value = RootOps.run("[ -e " + path + " ] && cat " + path + " || echo Unavailable");
        return value.isEmpty() ? "Unavailable" : value;
    }

    private static String mouse(String value) {
        if ("-1".equals(value)) return "Off";
        if ("310".equals(value) || "0x136".equals(value)) return "Top left trigger";
        if ("311".equals(value) || "0x137".equals(value)) return "Top right trigger";
        return value;
    }
}
