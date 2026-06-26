package in.malinimahal.app;

import android.os.Bundle;
import android.webkit.WebView;
import androidx.core.splashscreen.SplashScreen;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        SplashScreen.installSplashScreen(this);
        super.onCreate(savedInstanceState);
        try {
            WebView webView = getBridge().getWebView();
            if (webView != null) {
                webView.post(() -> {
                    try {
                        webView.evaluateJavascript(
                            "localStorage.setItem('mmAppMode','customer');" +
                            "window.dispatchEvent(new CustomEvent('mmAppModeChanged'));",
                            null
                        );
                    } catch (Exception ignored) {}
                });
            }
        } catch (Exception ignored) {}
    }
}
