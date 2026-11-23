package dev.novahub.app;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.view.KeyEvent;
import android.webkit.JavascriptInterface;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends Activity {
    private static final String FORSAKEN_MANIFEST =
        "https://raw.githubusercontent.com/Trotilov/nova-forsaken/main/nova-hub.json";
    private static final String ROYALE_MANIFEST =
        "https://raw.githubusercontent.com/Trotilov/nova-royale/main/nova-hub.json";
    private static final String STABLE_SCRIPT =
        "https://raw.githubusercontent.com/Trotilov/nova-forsaken/main/nova.lua";
    private static final String BETA_SCRIPT =
        "https://raw.githubusercontent.com/Trotilov/nova-forsaken/main/nova_beta.lua";
    private final ExecutorService executor = Executors.newFixedThreadPool(2);
    private WebView webView;
    private SharedPreferences cache;

    @Override public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(Color.rgb(9, 8, 10));
        getWindow().setNavigationBarColor(Color.rgb(9, 8, 10));
        cache = getSharedPreferences("nova-hub-cache", MODE_PRIVATE);
        webView = new WebView(this);
        webView.setBackgroundColor(Color.rgb(9, 8, 10));
        configureWebView();
        setContentView(webView);
        webView.loadUrl("file:///android_asset/index.html");
    }

    @SuppressLint("SetJavaScriptEnabled")
    private void configureWebView() {
        WebSettings s = webView.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(true); // Only bundled /android_asset files are loaded.
        s.setAllowContentAccess(false);
        s.setAllowFileAccessFromFileURLs(false);
        s.setAllowUniversalAccessFromFileURLs(false);
        s.setJavaScriptCanOpenWindowsAutomatically(false);
        webView.addJavascriptInterface(new Bridge(), "Nova");
        webView.setWebViewClient(new WebViewClient() {
            @Override public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                Uri url = request.getUrl();
                if ("file".equals(url.getScheme()) &&
                    "android_asset".equals(url.getHost())) return false;
                if ("https".equals(url.getScheme()) && "github.com".equals(url.getHost())) {
                    openExternal(url.toString());
                }
                return true;
            }
        });
    }

    private void postJs(String call) {
        runOnUiThread(() -> {
            if (webView != null) webView.evaluateJavascript(call, null);
        });
    }

    private void toast(String message) {
        runOnUiThread(() -> Toast.makeText(this, message, Toast.LENGTH_SHORT).show());
    }

    private String httpGet(String address, int maxBytes) throws Exception {
        HttpURLConnection c = (HttpURLConnection) new URL(address).openConnection();
        c.setConnectTimeout(10000);
        c.setReadTimeout(12000);
        c.setRequestMethod("GET");
        c.setRequestProperty("User-Agent", "NovaHub-Android/0.2");
        c.setInstanceFollowRedirects(false);
        try {
            if (c.getResponseCode() != 200)
                throw new IllegalStateException("HTTP " + c.getResponseCode());
            try (InputStream stream = c.getInputStream();
                 ByteArrayOutputStream bytes = new ByteArrayOutputStream()) {
                byte[] block = new byte[8192];
                int n;
                while ((n = stream.read(block)) != -1) {
                    if (bytes.size() + n > maxBytes) throw new IllegalStateException("File too large");
                    bytes.write(block, 0, n);
                }
                return bytes.toString(StandardCharsets.UTF_8.name());
            }
        } finally { c.disconnect(); }
    }

    private String manifestUrl(String project) {
        return "forsaken".equals(project) ? FORSAKEN_MANIFEST : ROYALE_MANIFEST;
    }

    private void sync(String project) {
        executor.execute(() -> {
            String data;
            boolean offline = false;
            try {
                data = httpGet(manifestUrl(project) + "?v=" + System.currentTimeMillis(), 90000);
                JSONObject json = new JSONObject(data);
                if (json.optInt("schema") != 1 || !project.equals(json.optString("project")))
                    throw new IllegalArgumentException("Invalid manifest");
                if ("forsaken".equals(project)) {
                    String url = json.optString("script_url");
                    if (!STABLE_SCRIPT.equals(url))
                        throw new SecurityException("Invalid script origin");
                }
                if ("forsaken".equals(project) && json.has("beta")) {
                    JSONObject beta = json.getJSONObject("beta");
                    if (!BETA_SCRIPT.equals(beta.optString("script_url")))
                        throw new SecurityException("Invalid beta script origin");
                }
                cache.edit().putString("manifest_" + project, data).apply();
            } catch (Exception e) {
                data = cache.getString("manifest_" + project, "");
                offline = true;
            }
            final String response = data;
            final String status = offline ? "cached" : "online";
            postJs("window.NovaApp && window.NovaApp.receiveManifest(" +
                JSONObject.quote(project) + "," + JSONObject.quote(response) + "," +
                JSONObject.quote(status) + ")");
        });
    }

    private void copyForsaken(String channel) {
        final boolean beta = "beta".equals(channel);
        final String url = beta ? BETA_SCRIPT : STABLE_SCRIPT;
        final String cacheKey = beta ? "forsaken_script_beta" : "forsaken_script_stable";
        final String label = beta ? "тестовая" : "стабильная";
        executor.execute(() -> {
            String script;
            boolean offline = false;
            try {
                script = httpGet(url + "?v=" + System.currentTimeMillis(), 450000);
                if (script.trim().length() < 30 || script.trim().startsWith("<"))
                    throw new IllegalArgumentException("Invalid script response");
                cache.edit().putString(cacheKey, script).apply();
            } catch (Exception e) {
                script = cache.getString(cacheKey, "");
                offline = true;
            }
            if (script.isEmpty()) {
                postJs("window.NovaApp && window.NovaApp.copyResult(false," +
                    JSONObject.quote("Скрипт недоступен. Проверь интернет.") + ")");
                return;
            }
            final String ready = script;
            final boolean fromCache = offline;
            runOnUiThread(() -> {
                ClipboardManager clipboard = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
                clipboard.setPrimaryClip(ClipData.newPlainText("Forsaken NOVA " + channel, ready));
                String message = fromCache ? "Скопирована сохранённая " + label + " версия (офлайн)" :
                    "Скопирована " + label + " версия NOVA";
                postJs("window.NovaApp && window.NovaApp.copyResult(true," + JSONObject.quote(message) + ")");
            });
        });
    }

    private void openExternal(String url) {
        if (!url.startsWith("https://github.com/Trotilov/")) {
            toast("Разрешены только ссылки наших проектов на GitHub");
            return;
        }
        try { startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url))); }
        catch (Exception e) { toast("Не удалось открыть GitHub"); }
    }

    private void launchRoyale() {
        runOnUiThread(() -> {
            Intent intent = getPackageManager().getLaunchIntentForPackage("dev.novaroyale.tracker");
            if (intent == null) {
                postJs("window.NovaApp && window.NovaApp.launchResult(false)");
                return;
            }
            try {
                startActivity(intent);
                postJs("window.NovaApp && window.NovaApp.launchResult(true)");
            } catch (Exception e) {
                postJs("window.NovaApp && window.NovaApp.launchResult(false)");
            }
        });
    }

    private final class Bridge {
        @JavascriptInterface public void refresh() {
            sync("forsaken"); sync("royale");
        }
        @JavascriptInterface public void copyScript(String channel) {
            if (!"stable".equals(channel) && !"beta".equals(channel)) {
                toast("Неизвестная версия скрипта");
                return;
            }
            copyForsaken(channel);
        }
        @JavascriptInterface public void launchRoyale() { MainActivity.this.launchRoyale(); }
        @JavascriptInterface public void openGitHub(String url) {
            runOnUiThread(() -> openExternal(url));
        }
    }

    @Override public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            postJs("window.NovaApp && window.NovaApp.back()");
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }

    @Override protected void onDestroy() {
        executor.shutdownNow();
        if (webView != null) webView.destroy();
        super.onDestroy();
    }
}
