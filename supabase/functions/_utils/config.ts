import * as OneSignal from "https://esm.sh/@onesignal/node-onesignal@2.0.1-beta2";

export const _OnesignalAppId_ = Deno.env.get("ONESIGNAL_APP_ID")!;
const _OnesignalUserAuthKey_ = Deno.env.get("USER_AUTH_KEY")!;
export const _OnesignalRestApiKey_ = Deno.env.get("ONESIGNAL_REST_API_KEY")!;

export const onesignal = new OneSignal.DefaultApi({
  // authMethods: {}
});
