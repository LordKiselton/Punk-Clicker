#!/usr/bin/env python3
# Симулятор экономики «Балагана» — оценивает темп первой сессии.
# Модель: активные тапы + idle-DPS труппы, жадные покупки. Значения из Balance.gd / Game.gd.
import math, sys
try: sys.stdout.reconfigure(encoding="utf-8")
except Exception: pass

# --- Balance.gd (итерация 3 тюнинга) ---
TAP_BASE, TAP_GROWTH = 6.0, 1.10
TAP_UP_BASE_COST, TAP_UP_GROWTH = 15.0, 1.15
HP_BASE, HP_GROWTH = 10.0, 1.17
GOLD_BASE, GOLD_GROWTH = 3.0, 1.155
ENEMIES_PER_STAGE, BOSS_EVERY = 10, 5
BOSS_HP_MULT, BOSS_GOLD_MULT, BOSS_TIMER = 7.0, 10.0, 30.0
CRIT_CHANCE, CRIT_MULT = 0.05, 2.0
MILESTONE_EVERY, MILESTONE_MULT = 15, 1.8
PRESTIGE_UNLOCK_STAGE, BELLS_K, BELLS_EXP = 75, 0.1, 1.5

# --- Труппа (Game.ALLIES) ---
ALLIES = {
    "Голова":   dict(dps=3.0,   cost=15.0,    growth=1.08),
    "Громобой": dict(dps=18.0,  cost=150.0,   growth=1.09),
    "Ведьма":   dict(dps=110.0, cost=1800.0,  growth=1.10),
    "Путник":   dict(dps=650.0, cost=22000.0, growth=1.11),
}
TPS = 5.0                       # тапов в секунду (активная игра)
CRIT_AVG = 1 + CRIT_CHANCE * (CRIT_MULT - 1)   # средний множитель тапа

def tap_damage(lvl): return TAP_BASE * TAP_GROWTH ** lvl
def tap_dps(lvl): return tap_damage(lvl) * TPS * CRIT_AVG
def ally_dps(name, lvl):
    if lvl <= 0: return 0.0
    d = ALLIES[name]
    return d["dps"] * lvl * MILESTONE_MULT ** (lvl // MILESTONE_EVERY)
def ally_cost(name, lvl): return ALLIES[name]["cost"] * ALLIES[name]["growth"] ** lvl
def tap_up_cost(lvl): return TAP_UP_BASE_COST * TAP_UP_GROWTH ** lvl
def enemy_hp(stage, boss): return HP_BASE * HP_GROWTH ** (stage-1) * (BOSS_HP_MULT if boss else 1)
def enemy_gold(stage, boss): return GOLD_BASE * GOLD_GROWTH ** (stage-1) * (BOSS_GOLD_MULT if boss else 1)

def total_idle(ally_lvls): return sum(ally_dps(n, l) for n, l in ally_lvls.items())

def try_buy(gold, tap_lvl, ally_lvls):
    """Жадно тратим золото: сперва открываем нового героя, иначе — лучший прирост DPS за золото."""
    bought = True
    while bought:
        bought = False
        # приоритет: открыть нового героя как только по карману
        for n in ALLIES:
            if ally_lvls[n] == 0 and gold >= ally_cost(n, 0):
                gold -= ally_cost(n, 0); ally_lvls[n] = 1; bought = True
        if bought: continue
        # иначе — лучший value = прирост боевого DPS / цена
        best, best_val = None, 0.0
        c = tap_up_cost(tap_lvl)
        if gold >= c:
            gain = tap_dps(tap_lvl+1) - tap_dps(tap_lvl)
            best, best_val, best_kind = ("tap", gain/c, "tap")
        for n in ALLIES:
            if ally_lvls[n] > 0:
                cc = ally_cost(n, ally_lvls[n])
                if gold >= cc:
                    gain = ally_dps(n, ally_lvls[n]+1) - ally_dps(n, ally_lvls[n])
                    v = gain/cc
                    if v > best_val: best, best_val, best_kind = (n, v, "ally")
        if best == "tap":
            gold -= tap_up_cost(tap_lvl); tap_lvl += 1; bought = True
        elif best is not None:
            gold -= ally_cost(best, ally_lvls[best]); ally_lvls[best] += 1; bought = True
    return gold, tap_lvl, ally_lvls

def mmss(t): return f"{int(t//60):02d}:{int(t%60):02d}"

def run():
    dt = 0.05
    t = 0.0
    gold = 0.0
    tap_lvl = 0
    ally_lvls = {n: 0 for n in ALLIES}
    stage = 1
    kills = 0
    unlocked = set()
    log = []
    boss = (stage % BOSS_EVERY == 0)
    hp = enemy_hp(stage, boss)
    boss_t = 0.0
    last_milestone = 0
    walls = []
    MAXT = 60*60   # 60 минут
    while t < MAXT and stage < 300:
        dps = tap_dps(tap_lvl) + total_idle(ally_lvls)
        hp -= dps * dt
        t += dt
        if boss:
            boss_t += dt
            if boss_t >= BOSS_TIMER and hp > 0:
                walls.append((t, stage, hp/enemy_hp(stage, True)))
                stage = max(1, stage-1)
                kills = 0
                boss = (stage % BOSS_EVERY == 0)
                hp = enemy_hp(stage, boss); boss_t = 0.0
                continue
        if hp <= 0:
            gold += enemy_gold(stage, boss)
            kills += 1
            need = 1 if boss else ENEMIES_PER_STAGE
            if kills >= need:
                stage += 1; kills = 0
            gold, tap_lvl, ally_lvls = try_buy(gold, tap_lvl, ally_lvls)
            for n in ALLIES:
                if ally_lvls[n] > 0 and n not in unlocked:
                    unlocked.add(n); log.append((t, stage, f"🎭 открыт союзник: {n}"))
            for ms in (10,25,50,75,100,150,200):
                if stage >= ms and last_milestone < ms:
                    last_milestone = ms
                    idle = total_idle(ally_lvls); td = tap_dps(tap_lvl)
                    share = 100*idle/max(1e-9, idle+td)
                    extra = " ← PRESTIGE доступен" if ms == 75 else ""
                    log.append((t, stage, f"📍 стадия {ms} (idle {share:.0f}%){extra}"))
            boss = (stage % BOSS_EVERY == 0)
            hp = enemy_hp(stage, boss); boss_t = 0.0
        # периодические покупки от idle-золота даже без киллов
    # вывод
    print("=== ТЕМП ПЕРВОЙ СЕССИИ (сим, TPS=%.0f) ===" % TPS)
    for (tt, st, ev) in log:
        print(f"  {mmss(tt)}  ст.{st:>3}  {ev}")
    print()
    print("Итог за %s: стадия %d, tap ур.%d" % (mmss(t), stage, tap_lvl))
    print("Уровни труппы:", {n: ally_lvls[n] for n in ALLIES})
    print("Боевой DPS: tap=%.0f  idle=%.0f  (idle доля %.0f%%)" % (
        tap_dps(tap_lvl), total_idle(ally_lvls),
        100*total_idle(ally_lvls)/max(1e-9, tap_dps(tap_lvl)+total_idle(ally_lvls))))
    if walls:
        print("\n⚠️ СТЕНЫ-БОССЫ (не уложился в %ds), первые 8:" % int(BOSS_TIMER))
        for (tt, st, frac) in walls[:8]:
            print(f"  {mmss(tt)}  босс ст.{st}: осталось {frac*100:.0f}% HP")
        print("  всего откатов:", len(walls))
    else:
        print("\nСтен-боссов не было (боссы проходятся с запасом — возможно, слишком легко).")
    if stage >= PRESTIGE_UNLOCK_STAGE:
        bells = int(BELLS_K * stage ** BELLS_EXP)
        print("\nPrestige на стадии %d дал бы %d бубенцов." % (stage, bells))

run()
