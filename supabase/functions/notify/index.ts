import {
  createConfiguration,
  DefaultApi,
  Notification,
} from "https://esm.sh/@onesignal/node-onesignal@2.0.1-beta2";

const _OnesignalAppId_ = Deno.env.get("ONESIGNAL_APP_ID")!;
const _OnesignalUserAuthKey_ = Deno.env.get("USER_AUTH_KEY")!;
const _OnesignalRestApiKey_ = Deno.env.get("ONESIGNAL_REST_API_KEY")!;
const configuration = createConfiguration({
  userKey: _OnesignalUserAuthKey_,
  appKey: _OnesignalRestApiKey_,
});

const onesignal = new DefaultApi(configuration);

Deno.serve(async (req) => {
  try {
    const {
      record: { im_fine, user_id },
    } = await req.json();

    if (im_fine == true) {
      return new Response(JSON.stringify({ status: "all ok" }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // Build OneSignal notification object
    const notification = new Notification();
    notification.app_id = _OnesignalAppId_;
    notification.include_external_user_ids = [user_id];
    // notification.url =
    notification.contents = {
      en: `יעקב לא ענה באפליקציה! תבדוק אם הוא בסדר`,
    };
    const onesignalApiRes = await onesignal.createNotification(notification);

    return new Response(
      JSON.stringify({ onesignalResponse: onesignalApiRes }),
      {
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    console.error("Failed to create OneSignal notification", err);
    return new Response("Server error.", {
      headers: { "Content-Type": "application/json" },
      status: 400,
    });
  }
});
