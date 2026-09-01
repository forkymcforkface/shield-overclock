package com.rootfan.shieldtools;

import android.app.Activity;
import android.app.AlertDialog;
import android.os.Bundle;
import android.widget.TextView;
import android.widget.Toast;

public final class FanModeActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        TextView background = new TextView(this);
        background.setText("");
        setContentView(background);
        new Thread(() -> {
            try {
                boolean auto = RootOps.readLong("/sys/devices/pwm-fan/temp_control") == 1;
                runOnUiThread(() -> showModes(auto ? 0 : 1));
            } catch (Exception error) {
                runOnUiThread(() -> {
                    Toast.makeText(this, "Fan control unavailable", Toast.LENGTH_LONG).show();
                    finish();
                });
            }
        }).start();
    }

    private void showModes(int selected) {
        String[] modes = {"Auto", "Max cooling"};
        AlertDialog dialog = new AlertDialog.Builder(this)
                .setTitle("Fan mode")
                .setSingleChoiceItems(modes, selected, null)
                .setNegativeButton("Cancel", (value, which) -> finish())
                .setOnCancelListener(value -> finish())
                .create();
        dialog.setOnShowListener(ignored -> dialog.getListView().setOnItemClickListener((parent, view, position, id) -> {
            dialog.dismiss();
            apply(position);
        }));
        dialog.show();
    }

    private void apply(int mode) {
        new Thread(() -> {
            try {
                if (mode == 0) RootOps.run("echo 1 > /sys/devices/pwm-fan/temp_control");
                else RootOps.run("echo 255 > /sys/devices/pwm-fan/target_pwm; echo 0 > /sys/devices/pwm-fan/temp_control");
                getSharedPreferences("overlay", MODE_PRIVATE).edit().putInt("fan_mode", mode).apply();
                runOnUiThread(() -> Toast.makeText(this, mode == 0 ? "Fan set to Auto" : "Fan set to Max cooling", Toast.LENGTH_SHORT).show());
            } catch (Exception error) {
                runOnUiThread(() -> Toast.makeText(this, "Fan setting failed", Toast.LENGTH_LONG).show());
            } finally {
                runOnUiThread(this::finish);
            }
        }).start();
    }
}
