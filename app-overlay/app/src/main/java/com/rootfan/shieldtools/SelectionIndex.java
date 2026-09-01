package com.rootfan.shieldtools;

public final class SelectionIndex {
    public static int find(String title, CharSequence[] items) {
        int separator = title.indexOf(':');
        if (separator < 0) return -1;
        String current = title.substring(separator + 1).trim().split("\\s+")[0];
        for (int index = 0; index < items.length; index++) {
            String item = items[index].toString().replace(" (Factory)", "").trim();
            if (current.equals(item)) return index;
        }
        return -1;
    }
}
