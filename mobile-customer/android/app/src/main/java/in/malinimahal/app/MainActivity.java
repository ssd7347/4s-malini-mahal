package in.malinimahal.app;

import android.os.Bundle;
import androidx.core.splashscreen.SplashScreen;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        SplashScreen.installSplashScreen(this);
        super.onCreate(savedInstanceState);
        getBridge().getWebView().post(() ->
            getBridge().getWebView().evaluateJavascript(
                "localStorage.setItem('mmAppMode','customer');window.dispatchEvent(new CustomEvent('mmAppModeChanged'));", null
            )
        );
    }
}
