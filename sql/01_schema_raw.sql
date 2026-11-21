CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.bixi_trips (
    startstationname            TEXT,
    startstationarrondissement  TEXT,
    startstationlatitude        TEXT,
    startstationlongitude       TEXT,
    endstationname              TEXT,
    endstationarrondissement    TEXT,
    endstationlatitude          TEXT,
    endstationlongitude         TEXT,
    starttimems                 TEXT,
    endtimems                   TEXT,
    source_file                 TEXT,
    loaded_at                   TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS raw.weather_hourly (
    id                  TEXT,
    temp                TEXT,
    dew_point_temp      TEXT,
    humidex             TEXT,
    windchill           TEXT,
    precip_amount       TEXT,
    relative_humidity   TEXT,
    station_pressure    TEXT,
    visibility          TEXT,
    wind_speed          TEXT,
    wind_direction      TEXT,
    weather_eng_desc    TEXT,
    ts_utc              TEXT,
    hour_local          TEXT,
    source_file         TEXT,
    loaded_at           TIMESTAMPTZ DEFAULT now()
);