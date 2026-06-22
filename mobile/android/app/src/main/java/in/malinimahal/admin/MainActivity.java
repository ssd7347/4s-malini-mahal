package in.malinimahal.admin;

import android.os.Bundle;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getBridge().getWebView().post(() ->
            getBridge().getWebView().evaluateJavascript(
                "localStorage.setItem('mmAppMode','admin');", null
            )
        );
    }
}
