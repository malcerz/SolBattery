using Toybox.Activity;
using Toybox.Lang;
using Toybox.Time;
using Toybox.WatchUi;
using Toybox.System;
using Toybox.Graphics;
using Toybox.FitContributor;

class SolBatteryView extends WatchUi.DataField {

    private var mFitField = null;
    private var mCurrentSolar = null;
    private var mBatteryField = null;
    private var mHasSolarSensor = false;

    function clampPercent(value) {
        if (value == null) {
            return 0;
        }

        if (value < 0) {
            return 0;
        }

        if (value > 100) {
            return 100;
        }

        return value.toNumber();
    }

    function initialize() {
        DataField.initialize();

        mFitField = createField(
            "solar_pct",
            0,
            FitContributor.DATA_TYPE_UINT8,
            {
                :mesgType => FitContributor.MESG_TYPE_RECORD,
                :units    => "%"
            }
        );

        mBatteryField = createField(
            "battery_pct",
            1,
            FitContributor.DATA_TYPE_UINT8,
            {
                :mesgType => FitContributor.MESG_TYPE_RECORD,
                :units    => "%"
            }
        );

        // Garmin zaleca zainicjalizować pola setData() już przy tworzeniu,
        // aby pola zostały utworzone w pliku FIT od początku aktywności.
        // Pole "solar" inicjalizujemy tylko, gdy urządzenie ma panel słoneczny —
        // w przeciwnym razie w ogóle nie logujemy danych o świetle.
        var stats = System.getSystemStats();
        mHasSolarSensor = (stats != null && stats has :solarIntensity);

        if (mFitField != null) {
            mFitField.setData(0);
        }
        if (mBatteryField != null) {
            mBatteryField.setData(0);
        }
    }

    
    function compute(info as Activity.Info) as Void {
        var stats = System.getSystemStats();

        var batteryValue = 0;
        if (stats != null && stats.battery != null) {
            batteryValue = clampPercent(stats.battery);
        }

        var solarValue = 0;
        if (stats != null && stats has :solarIntensity && stats.solarIntensity != null) {
            mHasSolarSensor = true;
            solarValue = clampPercent(stats.solarIntensity);
            mCurrentSolar = solarValue;
        } else {
            // Brak danych z sensora solar: zapisujemy 0 do FIT, a w UI pokazujemy "--%".
            mCurrentSolar = null;
        }

        if (mFitField != null) {
            mFitField.setData(solarValue);
        }

        if (mBatteryField != null) {
            mBatteryField.setData(batteryValue);
        }
    }


    function onUpdate(dc) {
        var bgColor  = Graphics.COLOR_WHITE;
        var fgColor  = Graphics.COLOR_BLACK;
        var subColor = Graphics.COLOR_DK_GRAY;

        var width  = dc.getWidth();
        var height = dc.getHeight();

        // Pełne czyszczenie ekranu za pomocą fillRectangle w celu uniknięcia nakładania warstw
        dc.setColor(bgColor, bgColor);
        dc.fillRectangle(0, 0, width, height);

        // ===== DANE =====
        var stats = System.getSystemStats();
        var batteryNum = 0;
        if (stats != null && stats.battery != null) {
            batteryNum = clampPercent(stats.battery);
        }
        var battery = batteryNum.format("%d") + "%";

        var clockTime = System.getClockTime();
        var timeStr = clockTime.hour.format("%02d") + ":" + clockTime.min.format("%02d");

        var solarStr = "--%";
        if (mHasSolarSensor && mCurrentSolar != null) {
            solarStr = mCurrentSolar.format("%d") + "%";
        }

        // ===== UI =====
        dc.setColor(subColor, Graphics.COLOR_TRANSPARENT);

        // Bateria (lewa strona)
        dc.drawText(
            5,
            height * 0.05,
            Graphics.FONT_MEDIUM,
            "B:" + battery,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        // Intensywność Solar (prawa strona)
        dc.drawText(
            width - 5,
            height * 0.05,
            Graphics.FONT_MEDIUM,
            "S:" + solarStr,
            Graphics.TEXT_JUSTIFY_RIGHT
        );

        // Godzina (środek)
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2,
            height * 0.25,
            Graphics.FONT_NUMBER_HOT,
            timeStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
}
