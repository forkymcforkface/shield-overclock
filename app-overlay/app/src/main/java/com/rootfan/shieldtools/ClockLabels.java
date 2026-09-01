package com.rootfan.shieldtools;

public final class ClockLabels {
    public static CharSequence[] forDialog(String title, String[] items) {
        String factory = null;
        if (title.contains("CPU Max Freq")) factory = "2014500";
        if (title.contains("GPU Max Freq")) factory = "998400";
        if (title.contains("RAM Max Freq")) factory = "1600";
        String[] labels = items.clone();
        if (factory == null) return labels;
        for (int index = 0; index < labels.length; index++) {
            if (factory.equals(labels[index].trim())) labels[index] += " (Factory)";
        }
        return labels;
    }
}
