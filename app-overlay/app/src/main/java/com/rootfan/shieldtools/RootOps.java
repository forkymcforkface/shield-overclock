package com.rootfan.shieldtools;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.concurrent.TimeUnit;

final class RootOps {
    static String run(String command) throws Exception {
        Process process = new ProcessBuilder("su", "-c", command).redirectErrorStream(true).start();
        if (!process.waitFor(10, TimeUnit.SECONDS)) {
            process.destroyForcibly();
            throw new IllegalStateException("Root command timed out");
        }
        BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
        StringBuilder output = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            if (output.length() > 0) output.append('\n');
            output.append(line);
        }
        int result = process.exitValue();
        if (result != 0) throw new IllegalStateException(output.toString());
        return output.toString().trim();
    }

    static long readLong(String path) throws Exception {
        return Long.parseLong(run("cat " + path).split("\\s+")[0]);
    }

    static String read(String path) throws Exception {
        return run("cat " + path).trim();
    }
}
