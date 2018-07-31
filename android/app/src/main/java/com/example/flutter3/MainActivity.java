package com.example.flutter3;

import android.content.Context;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.util.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import com.snapchat.kit.sdk.SnapLogin;
import com.snapchat.kit.sdk.core.controller.LoginStateController;
import com.snapchat.kit.sdk.core.models.MeData;
import com.snapchat.kit.sdk.core.models.UserDataResponse;
import com.snapchat.kit.sdk.login.networking.FetchUserDataCallback;

import java.util.LinkedHashMap;
import java.util.Map;

import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "thumbsOutChannel";
  Context cxt;
  Result res;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
    cxt = this;

    new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
            new MethodCallHandler() {
              @Override
              public void onMethodCall(MethodCall call,  Result result) {
                // TODO
                res = result;
                if(call.method.equals("snapchatLogin")){
                  SnapLogin.getLoginStateController(cxt).addOnLoginStateChangedListener(mLoginStateChangedListener);
                  SnapLogin.getAuthTokenManager(cxt).startTokenGrant();
                }
                if(call.method.equals("checkSnapchatLoginStatus")){
                  checkIfUserIsLoggedIn(cxt, res);
                }
                if(call.method.equals("getSnapId")){
                  getSnapId(cxt, res);
                }
                if(call.method.equals("logoutOfSnap")){
                  logoutOfSnap(cxt, res);
                }
                if(call.method.equals("snapGraph")){
                  snapGraph(cxt,res);
                }
              }
            });
  }

  final LoginStateController.OnLoginStateChangedListener mLoginStateChangedListener =
          new LoginStateController.OnLoginStateChangedListener() {

            @Override
            public void onLoginSucceeded() {
              snapGraph(cxt, res);
            }
            @Override
            public void onLoginFailed() {
              res.error("code 4", "log in failed", "error");
            }
            @Override
            public void onLogout() {

            }
          };


  public static void snapGraph(Context cxt, final Result res) {
    // Do something hereString
    String query = "{me{bitmoji{avatar},displayName,externalId}}";
    String variables = null;
    final Result result = res;
    SnapLogin.fetchUserData(cxt, query, variables, new FetchUserDataCallback() {
      @Override
      public void onSuccess(@Nullable UserDataResponse userDataResponse) {
        if (userDataResponse == null || userDataResponse.getData() == null) {
          return;
        }
        MeData meData = userDataResponse.getData().getMe();
        if (meData == null) {
          res.error("code 0", "no data", "error");
        }else{
          LinkedHashMap<String,String> info = new LinkedHashMap<String, String>();
          String url = meData.getBitmojiData().getAvatar();
          if( url != null){
            info.put("url", url);
          }
          info.put("name", meData.getDisplayName());
          info.put("id", meData.getExternalId());
          result.success(info);
        }
      }
      @Override
      public void onFailure(boolean isNetworkError, int statusCode) {
        final Result result = res;
        res.error("code 3", "graph failed", "error");

      }
    });
  }


  public static  void checkIfUserIsLoggedIn(Context cxt, final Result res){

    if(SnapLogin.isUserLoggedIn(cxt)){
      res.success("true");
    }else{
      res.success("false");
    }

  }

  public static void logoutOfSnap(Context cxt, final  Result res){
    SnapLogin.getAuthTokenManager(cxt).revokeToken();
    res.success("success");
  }


  public static void getSnapId(Context cxt, final Result res) {
    // Do something hereString
    String query = "{me{externalId}}";
    String variables = null;
    final Result result = res;
    SnapLogin.fetchUserData(cxt, query, variables, new FetchUserDataCallback() {
      @Override
      public void onSuccess(@Nullable UserDataResponse userDataResponse) {
        if (userDataResponse == null || userDataResponse.getData() == null) {
          return;
        }
        MeData meData = userDataResponse.getData().getMe();
        if (meData == null) {
          res.error("code 0", "no data", "error");
        }else{
          result.success(meData.getExternalId());
        }
      }
      @Override
      public void onFailure(boolean isNetworkError, int statusCode) {
        final Result result = res;
        if(isNetworkError){
          res.error("code 5", "log in failed", "network error");

        }else{
          res.error("code 1", "error", "error graph id");

        }

      }
    });
  }



}
