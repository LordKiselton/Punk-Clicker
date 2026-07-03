package com.balagan.metrica;

import io.appmetrica.analytics.AppMetrica;
import io.appmetrica.analytics.AppMetricaConfig;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

/**
 * Обёртка Яндекс AppMetrica для «Панк-Рок Кликер: ХОЙ!».
 * Активация + отправка событий воронки. Сессии/ретеншн/DAU SDK считает сам.
 * Регистрируется через meta-data org.godotengine.plugin.v2.BalaganMetrica.
 */
public class MetricaPlugin extends GodotPlugin {
    private boolean active = false;

    public MetricaPlugin(Godot godot) { super(godot); }

    @Override
    public String getPluginName() { return "BalaganMetrica"; }

    @UsedByGodot
    public void activate(String apiKey) {
        if (active) return;
        try {
            AppMetricaConfig config = AppMetricaConfig.newConfigBuilder(apiKey).build();
            AppMetrica.activate(getActivity().getApplicationContext(), config);
            AppMetrica.enableActivityAutoTracking(getActivity().getApplication());
            active = true;
        } catch (Exception e) { /* аналитика — не критичный путь */ }
    }

    @UsedByGodot
    public void reportEvent(String name) {
        try { if (active) AppMetrica.reportEvent(name); } catch (Exception e) { }
    }

    @UsedByGodot
    public void reportEventJson(String name, String jsonAttributes) {
        try { if (active) AppMetrica.reportEvent(name, jsonAttributes); } catch (Exception e) { }
    }
}
