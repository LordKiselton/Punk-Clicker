#!/usr/bin/env python3
# Симулятор экономики «Балагана» — первая сессия + prestige-петля.
# Значения синхронизированы с Balance.gd / Game.gd (8 героев, дерево «Сказаний»).
import math, sys
try: sys.stdout.reconfigure(encoding="utf-8")
except Exception: pass

# --- Balance.gd ---
TAP_BASE, TAP_GROWTH = 6.0, 1.10
TAP_UP_BASE_COST, TAP_UP_GROWTH = 15.0, 1.15
HP_BASE, HP_GROWTH = 10.0, 1.17
GOLD_BASE, GOLD_GROWTH = 3.0, 1.155
ENEMIES_PER_STAGE, BOSS_EVERY = 10, 5
BOSS_HP_MULT, BOSS_GOLD_MULT, BOSS_TIMER = 7.0, 10.0, 30.0
CRIT_CHANCE, CRIT_MULT = 0.05, 2.0
MILESTONE_EVERY, MILESTONE_MULT = 15, 1.8
PRESTIGE_UNLOCK_STAGE, BELLS_K, BELLS_EXP = 50, 1.0, 1.6
# дерево: эффект/ур, цена base*growth^owned. Мягкий рост цены → бубенцы реально работают.
META = {"gold": dict(per=0.60, cost=20, growth=1.16, cap=80),
        "dps":  dict(per=0.50, cost=18, growth=1.16, cap=80),
        "tap":  dict(per=0.60, cost=15, growth=1.16, cap=80),
        "start":dict(cost=25, growth=1.30, cap=20)}
START_GOLD_BASE, START_GOLD_GROWTH = 5000.0, 9.0

# --- Труппа (Game.ALLIES) — 8 героев ---
ALLIES = {
    "Рыцарь":    dict(dps=3.0,      cost=15.0),
    "Ведьма":    dict(dps=18.0,     cost=150.0),
    "Шут":       dict(dps=110.0,    cost=1800.0),
    "Могильщик": dict(dps=650.0,    cost=22000.0),
    "Кукловод":  dict(dps=3800.0,   cost=260000.0),
    "Шарманщик": dict(dps=22000.0,  cost=3.0e6),
    "Палач":     dict(dps=130000.0, cost=3.6e7),
    "Звонарь":   dict(dps=780000.0, cost=4.3e8),
}
GROWTHS = {"Рыцарь":1.08,"Ведьма":1.10,"Шут":1.11,"Могильщик":1.11,"Кукловод":1.12,"Шарманщик":1.12,"Палач":1.13,"Звонарь":1.13}
TPS = 5.0
CRIT_AVG = 1 + CRIT_CHANCE * (CRIT_MULT - 1)

def gmult(meta): return 1 + META["gold"]["per"]*meta.get("gold",0)
def dmult(meta): return 1 + META["dps"]["per"]*meta.get("dps",0)
def tmult(meta): return 1 + META["tap"]["per"]*meta.get("tap",0)
def start_gold(meta):
    l = meta.get("start",0)
    return 0.0 if l<=0 else START_GOLD_BASE*START_GOLD_GROWTH**(l-1)

def tap_damage(lvl,meta): return TAP_BASE*TAP_GROWTH**lvl*tmult(meta)
def tap_dps(lvl,meta): return tap_damage(lvl,meta)*TPS*CRIT_AVG
def ally_dps(n,lvl,meta):
    if lvl<=0: return 0.0
    return ALLIES[n]["dps"]*lvl*MILESTONE_MULT**(lvl//MILESTONE_EVERY)*dmult(meta)
def ally_cost(n,lvl): return ALLIES[n]["cost"]*GROWTHS[n]**lvl
def tap_up_cost(lvl): return TAP_UP_BASE_COST*TAP_UP_GROWTH**lvl
def enemy_hp(stage,boss): return HP_BASE*HP_GROWTH**(stage-1)*(BOSS_HP_MULT if boss else 1)
def enemy_gold(stage,boss,meta): return GOLD_BASE*GOLD_GROWTH**(stage-1)*(BOSS_GOLD_MULT if boss else 1)*gmult(meta)
def total_idle(lv,meta): return sum(ally_dps(n,l,meta) for n,l in lv.items())

def try_buy(gold,tap_lvl,lv,meta):
    bought=True
    while bought:
        bought=False
        for n in ALLIES:
            if lv[n]==0 and gold>=ally_cost(n,0):
                gold-=ally_cost(n,0); lv[n]=1; bought=True
        if bought: continue
        best,best_val=None,0.0
        c=tap_up_cost(tap_lvl)
        if gold>=c:
            best,best_val=("tap",(tap_dps(tap_lvl+1,meta)-tap_dps(tap_lvl,meta))/c)
        for n in ALLIES:
            if lv[n]>0:
                cc=ally_cost(n,lv[n])
                if gold>=cc:
                    v=(ally_dps(n,lv[n]+1,meta)-ally_dps(n,lv[n],meta))/cc
                    if v>best_val: best,best_val=(n,v)
        if best=="tap": gold-=tap_up_cost(tap_lvl); tap_lvl+=1; bought=True
        elif best: gold-=ally_cost(best,lv[best]); lv[best]+=1; bought=True
    return gold,tap_lvl,lv

def mmss(t): return f"{int(t//60):02d}:{int(t%60):02d}"

def run_life(meta, maxt=40*60):
    """Один забег до стены-босса (или лимита). Возвращает (max_stage, time)."""
    dt=0.05; t=0.0
    gold=start_gold(meta); tap_lvl=0
    lv={n:0 for n in ALLIES}; stage=1; kills=0; mx=1
    boss=(stage%BOSS_EVERY==0); hp=enemy_hp(stage,boss); bt=0.0
    fails=0
    gold,tap_lvl,lv=try_buy(gold,tap_lvl,lv,meta)
    while t<maxt:
        dps=tap_dps(tap_lvl,meta)+total_idle(lv,meta)
        hp-=dps*dt; t+=dt
        if boss:
            bt+=dt
            if bt>=BOSS_TIMER and hp>0:
                fails+=1
                if fails>=2:   # дважды не смог — это стена, пора в prestige
                    return mx,t
                stage=max(1,stage-1); kills=0
                boss=(stage%BOSS_EVERY==0); hp=enemy_hp(stage,boss); bt=0.0
                continue
        if hp<=0:
            gold+=enemy_gold(stage,boss,meta); kills+=1
            need=1 if boss else ENEMIES_PER_STAGE
            if kills>=need:
                stage+=1; kills=0; mx=max(mx,stage); fails=0
            gold,tap_lvl,lv=try_buy(gold,tap_lvl,lv,meta)
            boss=(stage%BOSS_EVERY==0); hp=enemy_hp(stage,boss); bt=0.0
    return mx,t

def spend_bells(meta,bells):
    """Игрок-приоритет: золото компаундит экономику → берём его агрессивнее,
    затем dps/tap, немного в start. Покупаем по кругу пока хватает."""
    order=["gold","gold","dps","tap","gold","start","dps","tap"]
    progressed=True
    while progressed:
        progressed=False
        for k in order:
            owned=meta.get(k,0)
            if owned>=META[k]["cap"]: continue
            c=math.ceil(META[k]["cost"]*META[k]["growth"]**owned)
            if c<=bells:
                bells-=c; meta[k]=owned+1; progressed=True
    return bells

def main():
    # --- первая жизнь (без prestige) ---
    meta={}
    s0,t0=run_life(meta)
    print("=== ПЕРВАЯ СЕССИЯ (без prestige) ===")
    print(f"  стена примерно на стадии {s0} за {mmss(t0)} (затем доступен сброс — порог {PRESTIGE_UNLOCK_STAGE})")

    # --- prestige-петля ---
    print("\n=== PRESTIGE-ПЕТЛЯ (жадная закупка дерева) ===")
    earned=0.0; bells=0; total_t=t0; best_overall=s0
    meta={}
    loops=[]
    rec=s0
    for loop in range(1,26):
        s,tt=run_life(meta)
        rec=max(rec,s)
        target=int(BELLS_K*rec**BELLS_EXP)
        gain=max(0,target-int(earned)); earned=float(target)
        bells+=gain; total_t+=tt
        bells=spend_bells(meta,bells)
        loops.append((loop,s,gain,total_t,dict(meta)))
        best_overall=max(best_overall,s)
        gold_m,dps_m,tap_m=gmult(meta),dmult(meta),tmult(meta)
        print(f"  заход {loop:>2}: ст.{s:>4}  +{gain:>4}🔔  ×{gold_m:.1f}з/×{dps_m:.1f}d/×{tap_m:.1f}т  всего {total_t/3600:.1f} ч")
        if gain<2 and loop>4:
            print("  → бубенцов почти нет (плато роста рекорда)"); break

    print(f"\nИтог: рекорд стадии {best_overall}, суммарно активной игры ~{total_t/3600:.1f} ч до плато.")

main()
