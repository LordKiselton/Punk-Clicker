package com.balagan.notify;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;

import org.json.JSONObject;

/**
 * Хранилище запланированных пушей + общая логика постановки аларма.
 * Используется и плагином (NotifyPlugin), и BootReceiver'ом после перезагрузки.
 */
public class NotifyStore {
    private static final String PREF = "balagan_notify";

    private static SharedPreferences prefs(Context ctx) {
        return ctx.getApplicationContext().getSharedPreferences(PREF, Context.MODE_PRIVATE);
    }

    static PendingIntent pending(Context ctx, int id, String title, String text) {
        Intent i = new Intent(ctx.getApplicationContext(), NotifyReceiver.class);
        i.setAction("com.balagan.NOTIFY_" + id);
        i.putExtra("id", id);
        i.putExtra("title", title);
        i.putExtra("text", text);
        return PendingIntent.getBroadcast(ctx.getApplicationContext(), id, i,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }

    static void arm(Context ctx, int id, String title, String text, long atMillis) {
        AlarmManager am = (AlarmManager) ctx.getApplicationContext().getSystemService(Context.ALARM_SERVICE);
        // неточный аларм — не требует SCHEDULE_EXACT_ALARM, для наших сценариев ок
        if (am != null) am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pending(ctx, id, title, text));
    }

    static void put(Context ctx, int id, String title, String text, long atMillis) {
        try {
            JSONObject o = new JSONObject();
            o.put("title", title);
            o.put("text", text);
            o.put("at", atMillis);
            prefs(ctx).edit().putString("n_" + id, o.toString()).apply();
        } catch (Exception e) { }
    }

    static void remove(Context ctx, int id) {
        prefs(ctx).edit().remove("n_" + id).apply();
    }

    static void clear(Context ctx) {
        prefs(ctx).edit().clear().apply();
    }

    /** После ребута/обновления: пере-заводим будущие алармы, прошедшие — чистим. */
    static void reschedule(Context ctx) {
        SharedPreferences p = prefs(ctx);
        long now = System.currentTimeMillis();
        SharedPreferences.Editor ed = p.edit();
        for (String key : p.getAll().keySet()) {
            if (!key.startsWith("n_")) continue;
            try {
                JSONObject o = new JSONObject(p.getString(key, "{}"));
                long at = o.optLong("at", 0);
                int id = Integer.parseInt(key.substring(2));
                if (at > now) {
                    arm(ctx, id, o.optString("title", ""), o.optString("text", ""), at);
                } else {
                    ed.remove(key);
                }
            } catch (Exception e) {
                ed.remove(key);
            }
        }
        ed.apply();
    }
}
