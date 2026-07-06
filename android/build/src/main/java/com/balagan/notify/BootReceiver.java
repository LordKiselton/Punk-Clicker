package com.balagan.notify;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/**
 * После перезагрузки телефона (или обновления приложения) AlarmManager чистит все алармы.
 * Здесь мы пере-заводим запланированные пуши из SharedPreferences (NotifyStore).
 */
public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context ctx, Intent intent) {
        String a = intent.getAction();
        if (a == null) return;
        if (!a.equals(Intent.ACTION_BOOT_COMPLETED)
                && !a.equals("android.intent.action.LOCKED_BOOT_COMPLETED")
                && !a.equals(Intent.ACTION_MY_PACKAGE_REPLACED)) return;
        try {
            NotifyStore.reschedule(ctx);
        } catch (Exception e) { }
    }
}
