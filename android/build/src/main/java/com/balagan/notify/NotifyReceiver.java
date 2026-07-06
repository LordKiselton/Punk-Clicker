package com.balagan.notify;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

/** Показывает запланированное уведомление; тап открывает игру. */
public class NotifyReceiver extends BroadcastReceiver {
    private static final String CH = "balagan";

    @Override
    public void onReceive(Context ctx, Intent intent) {
        try {
            NotificationManager nm = (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                nm.createNotificationChannel(
                        new NotificationChannel(CH, "Награды и напоминания", NotificationManager.IMPORTANCE_DEFAULT));
            }
            Intent launch = ctx.getPackageManager().getLaunchIntentForPackage(ctx.getPackageName());
            PendingIntent tap = PendingIntent.getActivity(ctx, 0, launch,
                    PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
            Notification.Builder b = (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    ? new Notification.Builder(ctx, CH)
                    : new Notification.Builder(ctx);
            String text = intent.getStringExtra("text");
            b.setSmallIcon(ctx.getApplicationInfo().icon)
                    .setContentTitle(intent.getStringExtra("title"))
                    .setContentText(text)
                    .setStyle(new Notification.BigTextStyle().bigText(text))
                    .setAutoCancel(true)
                    .setContentIntent(tap);
            int id = intent.getIntExtra("id", 1);
            nm.notify(id, b.build());
            NotifyStore.remove(ctx, id);   // сработал — убрать из хранилища пере-завода
        } catch (Exception e) { }
    }
}
