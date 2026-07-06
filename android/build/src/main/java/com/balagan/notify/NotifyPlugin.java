package com.balagan.notify;

import android.app.AlarmManager;
import android.content.Context;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

/**
 * Мини-плагин локальных уведомлений «Балагана»: AlarmManager + BroadcastReceiver.
 * Регистрируется через meta-data в AndroidManifest (org.godotengine.plugin.v2).
 * Запланированные пуши дублируются в NotifyStore (SharedPreferences), чтобы BootReceiver
 * мог пере-завести их после перезагрузки телефона (алармы при ребуте теряются).
 */
public class NotifyPlugin extends GodotPlugin {
    public NotifyPlugin(Godot godot) { super(godot); }

    @Override
    public String getPluginName() { return "BalaganNotify"; }

    private Context ctx() { return getActivity().getApplicationContext(); }

    @UsedByGodot
    public void schedule(int id, String title, String text, int delaySec) {
        try {
            long at = System.currentTimeMillis() + delaySec * 1000L;
            NotifyStore.arm(ctx(), id, title, text, at);
            NotifyStore.put(ctx(), id, title, text, at);   // для пере-завода после ребута
        } catch (Exception e) { /* пуши — не критичный путь */ }
    }

    @UsedByGodot
    public void cancel(int id) {
        try {
            AlarmManager am = (AlarmManager) ctx().getSystemService(Context.ALARM_SERVICE);
            if (am != null) am.cancel(NotifyStore.pending(ctx(), id, "", ""));
            NotifyStore.remove(ctx(), id);
        } catch (Exception e) { }
    }

    @UsedByGodot
    public void cancelAll() {
        for (int i = 1; i <= 8; i++) cancel(i);
        NotifyStore.clear(ctx());
    }
}
