package com.rootfan.shieldtools;

import android.app.Activity;
import android.app.AlertDialog;
import android.os.Bundle;
import android.widget.TextView;
import android.widget.Toast;

public final class MouseButtonActivity extends Activity {
    private static final String PATH = "/sys/module/hid_nvidia_blake/parameters/mouseClickButton";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(new TextView(this));
        new Thread(() -> {
            try {
                String value = RootOps.run("[ -e " + PATH + " ] && cat " + PATH + " || echo Unavailable");
                if ("Unavailable".equals(value)) throw new IllegalStateException();
                int selected = "310".equals(value) || "0x136".equals(value) ? 1 : "311".equals(value) || "0x137".equals(value) ? 2 : 0;
                runOnUiThread(() -> show(selected));
            } catch (Exception error) {
                runOnUiThread(() -> {
                    Toast.makeText(this, "Mouse-button control is not exposed by this kernel", Toast.LENGTH_LONG).show();
                    finish();
                });
            }
        }).start();
    }

    private void show(int selected) {
        String[] labels = {"Off", "Top left trigger", "Top right trigger"};
        String[] values = {"-1", "0x136", "0x137"};
        AlertDialog dialog = new AlertDialog.Builder(this)
                .setTitle("Mouse button")
                .setSingleChoiceItems(labels, selected, null)
                .setNegativeButton("Cancel", (value, which) -> finish())
                .setOnCancelListener(value -> finish())
                .create();
        dialog.setOnShowListener(ignored -> dialog.getListView().setOnItemClickListener((parent, view, position, id) -> {
            dialog.dismiss();
            new Thread(() -> {
                try {
                    RootOps.run("echo " + values[position] + " > " + PATH);
                    runOnUiThread(() -> Toast.makeText(this, "Mouse button set to " + labels[position], Toast.LENGTH_SHORT).show());
                } catch (Exception error) {
                    runOnUiThread(() -> Toast.makeText(this, "Mouse-button setting failed", Toast.LENGTH_LONG).show());
                } finally {
                    runOnUiThread(this::finish);
                }
            }).start();
        }));
        dialog.show();
    }
}
