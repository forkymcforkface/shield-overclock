package com.rootfan.shieldtools;

import android.app.Activity;
import android.app.AlertDialog;
import android.os.Bundle;
import android.widget.TextView;
import android.widget.Toast;

public final class TrackpadActivity extends Activity {
    private static final String PATH = "/sys/module/hid_nvidia_blake/parameters/speed";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(new TextView(this));
        new Thread(() -> {
            try {
                String result = RootOps.run("[ -e " + PATH + " ] && cat " + PATH + " || echo Unavailable");
                if ("Unavailable".equals(result)) throw new IllegalStateException();
                int current = Math.max(1, Math.min(10, Integer.parseInt(result)));
                runOnUiThread(() -> show(current - 1));
            } catch (Exception error) {
                runOnUiThread(() -> {
                    Toast.makeText(this, "Trackpad control is not exposed by this kernel", Toast.LENGTH_LONG).show();
                    finish();
                });
            }
        }).start();
    }

    private void show(int selected) {
        String[] values = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"};
        AlertDialog dialog = new AlertDialog.Builder(this)
                .setTitle("Trackpad speed")
                .setSingleChoiceItems(values, selected, null)
                .setNegativeButton("Cancel", (value, which) -> finish())
                .setOnCancelListener(value -> finish())
                .create();
        dialog.setOnShowListener(ignored -> dialog.getListView().setOnItemClickListener((parent, view, position, id) -> {
            dialog.dismiss();
            new Thread(() -> {
                try {
                    RootOps.run("echo " + (position + 1) + " > " + PATH);
                    runOnUiThread(() -> Toast.makeText(this, "Trackpad speed set to " + (position + 1), Toast.LENGTH_SHORT).show());
                } catch (Exception error) {
                    runOnUiThread(() -> Toast.makeText(this, "Trackpad setting failed", Toast.LENGTH_LONG).show());
                } finally {
                    runOnUiThread(this::finish);
                }
            }).start();
        }));
        dialog.show();
    }
}
