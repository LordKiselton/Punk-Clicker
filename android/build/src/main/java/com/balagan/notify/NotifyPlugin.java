package com.balagan.notify;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

/**
 * Мини-плагин локальных уведомлений «Балагана»: AlarmManager + BroadcastReceiver.
 * Регистрируется через meta-data в AndroidManifest (org.godotengine.plugin.v2).
 */
public class NotifyPlugin extends GodotPlugin {
    public NotifyPlugin(Godot godot) { super(godot); }

    @Override
    public String getPluginName() { return "BalaganNotify"; }

    private Context ctx() { return getActivity().getApplicationContext(); }

    private PendingIntent pending(int id, String title, String text) {
        Intent i = new Intent(ctx(), NotifyReceiver.class);
        i.setAction("com.balagan.NOTIFY_" + id);
        i.putExtra("id", id);
        i.putExtra("title", title);
        i.putExtra("text", text);
        return PendingIntent.getBroadcast(ctx(), id, i,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }

    @UsedByGodot
    public void schedule(int id, String title, String text, int delaySec) {
        try {
            AlarmManager am = (AlarmManager) ctx().getSystemService(Context.ALARM_SERVICE);
            long at = System.currentTimeMillis() + delaySec * 1000L;
            // неточный аларм — не требует SCHEDULE_EXACT_ALARM, для наших сценариев ок
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending(id, title, text));
        } catch (Exception e) { /* пуши — не критичный путь */ }
    }

    @UsedByGodot
    public void cancel(int id) {
        try {
            AlarmManager am = (AlarmManager) ctx().getSystemService(Context.ALARM_SERVICE);
            am.cancel(pending(id, "", ""));
        } catch (Exception e) { }
    }

    @UsedByGodot
    public void cancelAll() {
        for (int i = 1; i <= 8; i++) cancel(i);
    }
}
