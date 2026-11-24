%% track13_signals_from_orbit_demo
%% Signals from Orbit (album track 13): round trips from orbit, Doppler, the NTN channel, and HARQ
% In How Far, a few hundred metres of path were worth a microsecond. Now the 
% cell is served from orbit, by a satellite hundreds or tens of thousands 
% of kilometres up. The physics does not change, but the numbers get huge.
% 
% This demonstration works out round-trip times for a geostationary (GEO) 
% and a low-Earth-orbit (LEO) satellite from geometry, follows the Doppler 
% shift of a LEO pass, puts that shift into the toolbox channel and measures 
% it, and then counts what a long round trip does to stop-and-wait HARQ.
%% Guiding question
% How long are the delays and how large are the frequency shifts when the 
% cell is on a satellite, and what does a phone do about them?
% This demonstration
% 1. B1 — Round trips from geometry: slant range, transparent 4d/c and regenerative 
% 2d/c.
% 
% 2. B2 — Speed and Doppler over a LEO pass, by two routes.
% 
% 3. B3 — The NTN channel: SatelliteDopplerShift added, measured, removed, 
% and pre-compensated.
% 
% 4. B4 — The HARQ counterexample: how busy 32 processes keep a GEO link.
% 
% 5. Build it — From altitude and elevation to slant range, round trips, Doppler, 
% and HARQ processes.
% Key relationships
% Slant range from Earth radius R, altitude h, and elevation ε (degrees):
% 
% $$d(\varepsilon) = \sqrt{(R+h)^2 - R^2\cos^2\varepsilon} - R\sin\varepsilon$$
% 
% Round trips, with c = 299 792 458 m/s:
% 
% $$\mathrm{RTT}_{\mathrm{transparent}} = \frac{4d}{c},\qquad \mathrm{RTT}_{\mathrm{regenerative}} 
% = \frac{2d}{c}$$
% 
% Doppler for a satellite at speed v passing overhead, seen at elevation ε 
% (the form used in the toolbox NTN example), and its bound:
% 
% $$f_D(\varepsilon) = \frac{v f_c}{c}\cdot\frac{R\cos\varepsilon}{R+h},\qquad 
% |f_D| \le \frac{v f_c}{c}$$
% 
% Stop-and-wait HARQ with N processes, slot length T_slot:
% 
% $$\text{busy fraction} = \frac{\min(N,\ n_{\mathrm{RTT}})}{n_{\mathrm{RTT}}},\qquad 
% n_{\mathrm{RTT}} = \left\lceil \frac{\mathrm{RTT}}{T_{\mathrm{slot}}} \right\rceil$$
% Key ideas to remember
% • A geostationary satellite sits 35 786 km up; at the edge of its coverage 
% (10° elevation) the phone is more than 40 000 km away.
% 
% • A transparent satellite relays the signal: phone to satellite to ground 
% gateway and back, so the round trip is 4d/c, up to about 540 ms for GEO. 
% A regenerative satellite decodes on board, so the round trip is 2d/c, about 
% 270 ms. At 600 km (LEO) the worst cases are about 26 ms and 13 ms.
% 
% • A LEO satellite moves at about 7.5 km/s; near 2 GHz that is tens of kilohertz 
% of Doppler, and the sign flips as it passes overhead.
% 
% • The phone pre-shifts both its timing and its frequency before it transmits. 
% It knows its own position from GNSS and the satellite's from the ephemeris; 
% the distance sets the timing advance and the rate of change of distance 
% sets the frequency shift. What the geometry predicts is removed before transmission; 
% only the unpredictable remainder is left for the receiver.
% 
% • There is no new satellite channel object: nrTDLChannel takes NTN delay 
% profiles (NTN-TDL-A to NTN-TDL-D, NTN-TDLA100, NTN-TDLC5) and a SatelliteDopplerShift 
% property (R2024a or later), and the object applies that common shift.
% 
% • The toolbox's HARQ allows up to 32 processes, and each one waits for 
% its answer before it sends again. With 1 ms slots and a round trip near 
% 540 ms, 32 processes keep the link only about 6 % busy.
% 
% • The standard lets NTN links skip some of that HARQ feedback.
% Prerequisites
% • Range from delay, d = cτ (album track 12 How Far, track12/track12_how_far_demo).
% 
% • HARQ processes and redundancy versions (album track 05 Say It Again, track05/track05_say_it_again_demo).
% 
% • nrTDLChannel, delay profiles, and Doppler (album track 06 Taps in Time, 
% track06/track06_taps_in_time_demo).
% 
% • OFDM modulation and the resource grid (track 00 Fundamentals, track00_fundamentals/p00a_ofdm_and_cp_demo).
% Words used in this demo
% • NTN (non-terrestrial network): a cell served from a satellite or other 
% airborne platform. GEO / LEO: geostationary / low Earth orbit.
% 
% • Slant range: the straight-line distance from the phone to the satellite. 
% Elevation: the angle of the satellite above the horizon.
% 
% • Transparent (bent-pipe) payload: relays the waveform to a ground gateway. 
% Regenerative payload: decodes on board. Service link: phone to satellite; 
% feeder link: satellite to gateway.
% 
% • Timing advance: sending early by the round trip, so the uplink lands on 
% the base station's slot grid. Ephemeris: published orbit data for the satellite.
% 
% • Pre-compensation: shifting timing or frequency at the transmitter by the 
% predicted amount, before anyone measures it. Receiver correction: removing 
% a measured shift after reception.
% Key code terms to remember
% Each entry gives the purpose, the inputs, and the outputs. Commands you write 
% yourself (in the Build it, the Try its, and the exercises) get their own entry; 
% small helpers are grouped into families. Commands used in only one beat are 
% listed at the start of that beat.
% 
% Commands you write
% • x = value and [a b c] — Purpose: store a value or a row of values under 
% a name. Inputs: a name, then values. Outputs: the variable x.
% 
% • + - * / and ^ — Purpose: arithmetic and powers. Inputs: numbers. Outputs: 
% the result.
% 
% • sqrt(x) — Purpose: square root. Inputs: a number. Outputs: the root.
% 
% • sind(e) and cosd(e) — Purpose: sine and cosine of an angle in degrees. 
% Inputs: an angle in degrees. Outputs: a number from −1 to 1.
% 
% • ceil(x) — Purpose: round up to a whole number (a whole number of slots). 
% Inputs: a number. Outputs: a whole number.
% 
% Commands you read in the given code
% • carrier = nrCarrierConfig(...), ofdmInfo = nrOFDMInfo(carrier), nrResourceGrid, 
% nrOFDMModulate — Purpose: a carrier, its sample rate, an empty grid, and 
% a waveform. Inputs: spacing (kHz), RBs; a grid. Outputs: objects, a structure, 
% a grid, a waveform.
% 
% • nrTDLChannel with an NTN profile — Used in B3; listed there.
% 
% • Figure family: figure(Name = ...), plot, yline, xline, legend, grid on, 
% xlabel, ylabel, title — Purpose: draw curves and label them. Inputs: data 
% and text. Outputs: a figure.
% 
% Families you read in the given code
% • Punctuation: ; ... % %% — Purpose: hide the echo; continue a line; start 
% a comment; start a section. Inputs: a statement or text. Outputs: none shown.
% 
% • Indexing, ranges, and loops: x(k), x(end), a:b:c, for k = ... end, if 
% ... end, while ... end, break — Purpose: read or write entries, step through 
% values, repeat, choose. Inputs: arrays, ranges, tests. Outputs: the entries 
% or the repeated work.
% 
% • Compare and combine: == < > <= >=, ~, &&, any, all, find — Purpose: compare 
% values; not; and; any or every entry true; where a test is true. Inputs: 
% numbers or arrays. Outputs: true/false or indices.
% 
% • Built-in helpers: abs, max, min, sum, numel, zeros, round, sign, repmat, 
% angle, conj, exp, pi, isnan, NaN — Purpose: sizes, 
% differences, interpolation, angles, complex helpers. Inputs: numbers or arrays. 
% Outputs: numbers or arrays (NaN means "no number yet").
% 
% • Text: 'text', "text", "a" + "b", string, strjoin, and f = @(v) ... — Purpose: 
% write and join text, turn numbers into text, and make a one-line helper such 
% as slant or rtt. Inputs: text or numbers. Outputs: text, or a function.
% 
% • Tables, checks, and housekeeping: table(..., VariableNames = {...}), assert(test, 
% message), error, fprintf, disp, exist, isMATLABReleaseOlderThan, clear, 
% close all, rng(seed) — Purpose: show columns side by side, stop with a hint 
% when a check fails, stop early with a message, print a banner or note, check 
% the release, remove variables or figures, repeat random values. Inputs: 
% columns, a test and message, text, names, a seed. Outputs: a shown table 
% or line; an error if a check fails.
% Working status
% Status: unverified until M runs it in R2024b.
% 
% Teaching draft built to the track01 r03 template (track13 r01, 2026-11-20) 
% from the live track13_demo.m on main 2881359. No run of this file has been 
% recorded yet; a clean run is not a teaching sign-off, so read each table and 
% figure against its interpretation sentence. Requires the 5G Toolbox, R2024a 
% or later (the NTN delay profiles and SatelliteDopplerShift); Staging stops 
% with a message on an older release. Round trips are propagation only (no 
% processing time), on a spherical Earth of radius 6371 km, which reproduces 
% the TR 38.821 Table 4.2-2 slant ranges. GNSS and ephemeris are described 
% in words only. Teaching demo, not production code; not affiliated with 
% or endorsed by MathWorks.
%% Staging for script

clear; close all;   % empty workspace and no open figures, so every run starts from the same state
rng(2026);          % fixed random seed (any whole number works; 2026 is the album year); the channel in B3 has its own seed

% Stop early with a clear message if the release is too old for the NTN channel properties.
if isMATLABReleaseOlderThan("R2024a")
    error('This track needs R2024a or later: nrTDLChannel NTN profiles and SatelliteDopplerShift arrived in R2024a.')
end

% listText turns a list of numbers into one line of text, for example
% [1 2 4] becomes "1 2 4", so one row of a check table can show a whole list.
listText = @(v) strjoin(string(v(:).'), " ");

c = 299792458;    % speed of light, m/s: the exact value TR 38.821 uses
R = 6371e3;       % Earth radius, m: reproduces the TR 38.821 slant ranges
hGEO = 35786e3;   % geostationary altitude, m
hLEO = 600e3;     % LEO altitude, m (the TR 38.821 LEO-600 case)
elevMin = 10;     % lowest elevation served, degrees (the TR 38.821 edge of coverage)
vLEO = 7.5e3;     % LEO speed, m/s (about 7.56 km/s at 600 km; the song's round 7.5)
fc = 2e9;         % carrier frequency, Hz (S band, near 2 GHz)
tSlot = 1e-3;     % slot length, s: 1 ms at 15 kHz spacing
nHarqMax = 32;    % most HARQ processes the toolbox's nrDLSCH allows

% Two one-line helpers used in every beat: slant range and round trip.
slant = @(h, e) sqrt((R + h).^2 - (R*cosd(e)).^2) - R*sind(e);   % m, for altitude h (m) and elevation e (degrees)
rtt = @(d, legs) legs*d/c;                                        % s; legs = 4 transparent, 2 regenerative
%% B1 — Round trips from geometry
% New words
% • Nadir: straight below the satellite (90° elevation). Edge of coverage: 
% the lowest elevation the system serves, here 10°.
% Beat-only commands
% None beyond Staging: slant and rtt are the two helpers defined there.
% Why it matters
% A transparent satellite relays the waveform, so the radio path is phone, 
% satellite, gateway, satellite, phone: four slant ranges, 4d/c. A regenerative 
% payload ends the link on the satellite: two slant ranges, 2d/c. The slant 
% range grows fast as the satellite sinks toward the horizon, so the worst 
% case is at the edge of coverage, not overhead. TR 38.821 lists these distances; 
% the formula in Key relationships reproduces them.
% What to look for
% • In the round-trip table: the slant range and both round trips for each 
% orbit, overhead and at the edge.
% Common mistakes
% Do not quote 2d/c for a transparent satellite: that is half its round trip.
% 
% Do not use 3e8 for c at GEO distances: the 0.07 % error is a third of a 
% millisecond.
% Try it (personal exploration)
% Predict the transparent round trip, in milliseconds, for a LEO satellite 
% at 1200 km straight overhead. Type it into myPrediction before you run this 
% section; the one-row table at the end computes it.

% Try it: type your prediction here (ms) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B1 — Round trips from geometry
fprintf("B1 — Round trips from geometry\n");   % banner title only; every number below goes into a table

% Four cases: each orbit overhead (90 degrees) and at the edge of coverage.
caseOrbit = ["GEO"; "GEO"; "LEO 600 km"; "LEO 600 km"];
caseH = [hGEO; hGEO; hLEO; hLEO];        % altitude of each case, m
caseElev = [90; elevMin; 90; elevMin];   % elevation of each case, degrees
caseD = slant(caseH, caseElev);          % slant ranges, m

rttGeoEdge = rtt(caseD(2), 4);   % worst-case GEO transparent round trip, s (kept for B4)
rttLeoEdge = rtt(caseD(4), 4);   % worst-case LEO-600 transparent round trip, s (kept for B4)

% Two tests against TR 38.821 Table 4.2-2: the GEO edge distance and its transparent round trip.
trGeoEdgeKm = 40581;    % TR 38.821 Table 4.2-2: GEO maximum distance at 10 degrees, km
trGeoRttMs = 541.46;    % TR 38.821: GEO transparent maximum round trip, ms
okSlant = abs(caseD(2)/1e3 - trGeoEdgeKm) < 1;
assert(okSlant, ...
    'The GEO slant range at 10 degrees should be about 40581 km. Look first at the angle functions: the formula needs sind and cosd, because the elevation is in degrees.');
okRtt = abs(rttGeoEdge*1e3 - trGeoRttMs) < 0.05;
assert(okRtt, ...
    'The GEO transparent round trip should be 541.46 ms. Common mistake: c = 3e8, or two legs instead of four.');

b1Rtt = table(caseOrbit, caseElev, round(caseD/1e3, 1), round(rtt(caseD, 4)*1e3, 2), ...
    VariableNames = {'Orbit', 'Elevation_deg', 'SlantRange_km', 'Transparent_ms'});
b1Rtt

% Put your Try-it prediction beside the round trip for 1200 km overhead.
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b1Prediction = table(myPrediction, round(rtt(slant(1200e3, 90), 4)*1e3, 2), predictionNote, ...
    VariableNames = {'MyPrediction', 'Transparent_ms_1200km_overhead', 'Note'});
b1Prediction
%%
% Overhead, the slant range is just the altitude; at 10° it is longer, by 
% about 13 % for GEO and more than three times for LEO. The GEO transparent 
% round trip at the edge is the 541 ms of TR 38.821. LEO round trips are 
% tens of milliseconds at most. Compare the 1200 km round trip with your 
% prediction.
%% B1 — Assertion checks

% One row per assert in B1. Pass is computed from the stored flags.
b1Checks = table( ...
    ["GEO slant range at 10 degrees"; ...
     "GEO transparent round trip at 10 degrees"], ...
    [string(trGeoEdgeKm) + " km (TR 38.821)"; string(trGeoRttMs) + " ms (TR 38.821)"], ...
    [string(round(caseD(2)/1e3, 1)) + " km"; string(round(rttGeoEdge*1e3, 2)) + " ms"], ...
    [okSlant; okRtt], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b1Checks
%% B1 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep rttGeoEdge and rttLeoEdge: B4 counts HARQ processes against them.
clear b1Rtt b1Checks b1Prediction predictionNote okSlant okRtt ...
      caseOrbit caseH caseElev caseD trGeoEdgeKm trGeoRttMs myPrediction
%% B2 — Speed and Doppler over a LEO pass
% New words
% • Range rate: how fast the slant range changes, in m/s. Doppler shift: 
% the frequency offset it causes, −(f_c/c) × range rate.
% Beat-only commands
% • diff(x) — differences of neighbouring entries. diff(d)./diff(t) is a 
% numerical rate of change. interp1(x, y, xq) — read y at new points xq by 
% straight-line interpolation ('extrap' allows a point just past the ends). deg2rad, acosd, asind — degrees to radians, 
% and inverse cosine or sine in degrees.
% Why it matters
% A LEO satellite crosses the sky in minutes. While it approaches, the range 
% shrinks and the carrier arrives high; overhead the range stops changing 
% and the Doppler crosses zero; as it leaves, the shift is negative. The size 
% is v·f_c/c at most, times a geometry factor that the toolbox NTN example 
% writes with the elevation. This beat gets the Doppler two ways: by differentiating 
% the slant range along a pass, and from the elevation formula in Key relationships. 
% If they agree, the formula can be trusted to set SatelliteDopplerShift in 
% B3.
% What to look for
% • In the Doppler table: the shift at four elevations on the way up, by 
% both routes, and the bound v·f_c/c.
% 
% • In the figure: the Doppler over the pass, positive then negative, crossing 
% zero overhead.
% Common mistakes
% Do not bring terrestrial intuition (a few hundred hertz for a car) to a 
% LEO pass: here it is tens of kilohertz.
% 
% Do not forget the sign change overhead: a correction with a fixed sign 
% is right for only half the pass.
% Try it (personal exploration)
% Predict the bound v·f_c/c, in kHz, for the same satellite at a 3.5 GHz carrier. 
% Type it into myPrediction before you run this section; the one-row table 
% at the end computes it.

% Try it: type your prediction here (kHz) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B2 — Speed and Doppler
fprintf("B2 — Speed and Doppler over a LEO pass\n");   % banner title only; every number below goes into a table

% One pass straight overhead, from the edge of coverage on one side to the other.
r = R + hLEO;                                          % orbit radius, m
phiMax = acosd(R*cosd(elevMin)/r) - elevMin;           % Earth-centre angle at the edge of coverage, degrees
phi = (-phiMax:0.01:phiMax).';                         % Earth-centre angle along the pass, degrees (0 = overhead; step fine enough for diff)
tPass = deg2rad(phi)*r/vLEO;                           % time from overhead, s
dPass = sqrt(r^2 + R^2 - 2*r*R*cosd(phi));             % slant range along the pass, m (law of cosines)

% Route 1: Doppler from the numerical range rate, at the midpoints between samples.
fdNum = -fc/c*diff(dPass)./diff(tPass);                % Hz; positive while the satellite approaches
phiMid = (phi(1:end-1) + phi(2:end))/2;                % midpoint angles, degrees
dMid = sqrt(r^2 + R^2 - 2*r*R*cosd(phiMid));           % slant range at the midpoints, m
elevMid = asind((r*cosd(phiMid) - R)./dMid);           % elevation at the midpoints, degrees

% Route 2: the elevation formula, with the sign of approach (before overhead) or departure.
fDmax = vLEO*fc/c;                                     % the bound, Hz
fdFormula = -sign(phiMid).*fDmax.*R.*cosd(elevMid)/r;  % Hz

% One test: the two routes agree everywhere on the pass.
okDoppler = max(abs(fdNum - fdFormula)) < 0.005*fDmax;
assert(okDoppler, ...
    'The range-rate Doppler should match the elevation formula. Look first at elevMid: it must be in degrees and computed at the same midpoints as fdNum.');

% Read both routes at four elevations on the way up.
elevTable = [10; 30; 60; 89];                          % elevations to tabulate, degrees (89: just before overhead)
up = phiMid < 0;                                       % the approaching half of the pass
b2Doppler = table(elevTable, round(interp1(elevMid(up), fdNum(up), elevTable, 'linear', 'extrap')/1e3, 2), ...
    round(fDmax*R*cosd(elevTable)/r/1e3, 2), repmat(round(fDmax/1e3, 2), 4, 1), ...
    VariableNames = {'Elevation_deg', 'FromRangeRate_kHz', 'FromFormula_kHz', 'Bound_kHz'});
b2Doppler

% Mechanism figure: the Doppler over the pass, with the bound.
figure(Name = 'Track 13 - LEO Doppler over a pass', Color = 'w');
plot((tPass(1:end-1) + tPass(2:end))/2, fdNum/1e3);   % Doppler at each midpoint time
hold on;
yline([fDmax -fDmax]/1e3, ':k');
yline(0, '-k');
grid on;
xlabel('time from overhead (s)');
ylabel('Doppler (kHz)');
title('B2: the Doppler sign flips as the satellite passes overhead');

% Put your Try-it prediction beside the bound at 3.5 GHz.
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b2Prediction = table(myPrediction, round(vLEO*3.5e9/c/1e3, 2), predictionNote, ...
    VariableNames = {'MyPrediction', 'Bound_kHz_at_3p5GHz', 'Note'});
b2Prediction
%%
% The two routes agree, so the elevation formula is the range rate written 
% another way. At the edge of coverage the shift is already close to the 
% bound of about 50 kHz; it shrinks as the satellite climbs and crosses zero 
% overhead, then repeats with the opposite sign. Compare the 3.5 GHz bound 
% with your prediction.
%% B2 — Assertion checks

% One row per assert in B2. Pass is computed from the stored flag.
b2Checks = table("Range-rate route matches the elevation formula", ...
    "< " + string(round(0.005*fDmax)) + " Hz apart", ...
    string(round(max(abs(fdNum - fdFormula)), 2)) + " Hz max", okDoppler, ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b2Checks
%% B2 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Nothing later needs the pass; B3 sets its own shift.
clear b2Doppler b2Checks b2Prediction predictionNote okDoppler ...
      r phiMax phi tPass dPass fdNum phiMid dMid elevMid fDmax fdFormula elevTable up myPrediction
%% B3 — The NTN channel: add the shift, measure it, remove it, pre-compensate
% New words
% • Probe: a known test signal, here one subcarrier at 0 Hz on every symbol, 
% so the transmitted waveform is a constant and any phase ramp at the receiver 
% is a frequency shift.
% Beat-only commands
% • ch = nrTDLChannel(DelayProfile = "NTN-TDL-C", DelaySpread = s, MaximumDopplerShift 
% = 0, SatelliteDopplerShift = f, SampleRate = fs, NumReceiveAntennas = 1, 
% RandomStream = "mt19937ar with seed", Seed = n) — a satellite channel with 
% a fixed common shift f in Hz. rx = ch(wave) passes a waveform through it.
% 
% • angle(sum(conj(r(1:end-1)).*r(2:end))) — the average phase step from 
% one sample to the next; times fs/(2π) it is a frequency in Hz.
% Why it matters
% R2024a's nrTDLChannel has SatelliteDopplerShift, used with the NTN delay 
% profiles. The demo applies a known shift and measures it from the phase 
% ramp. With both Doppler properties set to 0 the channel is static, which 
% proves the shift comes from SatelliteDopplerShift alone. Removing the measured 
% shift at the receiver is receiver correction. Pre-compensation is different: 
% the phone shifts its own transmission by the amount the geometry predicts, 
% before anything is measured, so only the part it could not predict arrives. 
% The probe sits on the 0 Hz row of the grid, K/2 + 1; a probe on row 1 would 
% be a tone at −4.68 MHz, and the estimator would measure that tone instead.
% What to look for
% • In the shift table: the applied shift, the measured shift, the shift 
% left after receiver correction, and the static channel.
% Common mistakes
% Do not correct with the wrong sign: that doubles the offset instead of removing 
% it.
% 
% Do not expect a plain TDL delay profile from album track 06 to include the 
% satellite's common Doppler: SatelliteDopplerShift is a separate property.
% Try it (personal exploration)
% The phone predicts the shift from GNSS and the ephemeris, but its prediction 
% is 19.5 kHz while the true shift is 20 kHz. It pre-shifts its transmission 
% by minus its prediction. Predict the shift, in Hz, that the receiver then 
% measures. Type it into myPrediction before you run this section; the one-row 
% table at the end sends the pre-shifted probe through the same channel.

% Try it: type your prediction here (Hz) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B3 — The NTN channel
fprintf("B3 — The NTN channel\n");   % banner title only; every number below goes into a table

% A 15 kHz carrier and a constant probe: one subcarrier at 0 Hz on all 14 symbols.
carrier = nrCarrierConfig(SubcarrierSpacing = 15, NSizeGrid = 52);   % kHz, RBs (624 subcarriers)
ofdmInfo = nrOFDMInfo(carrier);
fs = ofdmInfo.SampleRate;                % 15.36 MHz for this carrier
txGrid = nrResourceGrid(carrier);
kDC = carrier.NSizeGrid*12/2 + 1;        % grid row at 0 Hz: K/2 + 1 (12 subcarriers per RB)
txGrid(kDC, :) = 1;                      % the probe on every symbol
wave = nrOFDMModulate(carrier, txGrid);  % a constant waveform
t = (0:numel(wave) - 1).'/fs;            % sample times, s

applied = 20e3;          % common satellite shift, Hz (a mid-pass LEO-scale value from B2)
delaySpread = 30e-9;     % NTN-TDL-C delay spread, s (a short, LOS-dominated spread)
chSeed = 13;             % channel seed, so every channel below has the same paths

% One satellite channel per case, all with the same profile and seed.
makeNtn = @(fSat) nrTDLChannel(DelayProfile = "NTN-TDL-C", DelaySpread = delaySpread, ...
    MaximumDopplerShift = 0, SatelliteDopplerShift = fSat, SampleRate = fs, ...
    NumReceiveAntennas = 1, RandomStream = "mt19937ar with seed", Seed = chSeed);
estF = @(r) angle(sum(conj(r(1:end-1)).*r(2:end)))*fs/(2*pi);   % average phase step, as a frequency in Hz

% Case 1: the satellite shift on. Divide by the probe and read the ramp
% (skip the channel's start-up samples, where the output is still near zero).
chOn = makeNtn(applied);                 % shift on
rx = chOn(wave);
ok = abs(rx) > 0.5*max(abs(rx));          % samples after the channel's start-up
fHat = estF(rx(ok)./wave(ok));            % measured shift, Hz

% Case 2: receiver correction, removing the measured shift.
rxFix = rx.*exp(-1j*2*pi*fHat*t);
fRes = estF(rxFix(ok)./wave(ok));         % what is left, Hz

% Case 3: both Doppler properties 0, so the channel is static.
chOff = makeNtn(0);                      % both Doppler properties 0
rx0 = chOff(wave);
ok0 = abs(rx0) > 0.5*max(abs(rx0));
f0 = estF(rx0(ok0)./wave(ok0));           % should be close to 0 Hz

% Two tests: the measured shift matches the applied one, and the static channel adds none.
okMeasure = abs(fHat - applied) < 0.01*abs(applied);
assert(okMeasure, ...
    'The measured shift should match SatelliteDopplerShift within 1 percent. Look first at Measured_Hz in b3Shift: if it is -applied, the sign convention is reversed (report the table); if it is far off, check kDC = K/2 + 1.');
okStatic = abs(f0) < 0.001*abs(applied);
assert(okStatic, ...
    'With both Doppler properties 0 the channel should add no shift. Look first at the channel settings: both Doppler properties must be 0 for a static channel.');

b3Shift = table(["Satellite shift on"; "After receiver correction"; "Both Doppler properties 0"], ...
    [applied; 0; 0], round([fHat; fRes; f0], 2), ...
    VariableNames = {'Case', 'Applied_Hz', 'Measured_Hz'});
b3Shift

% Put your Try-it prediction beside the pre-compensated probe.
fPredicted = 19.5e3;                                  % the phone's predicted shift, Hz (Try it)
wavePre = wave.*exp(-1j*2*pi*fPredicted*t);           % the phone pre-shifts by minus its prediction
chPre = makeNtn(applied);                             % the same channel, fresh object
rxPre = chPre(wavePre);
okPre = abs(rxPre) > 0.5*max(abs(rxPre));
fPre = estF(rxPre(okPre)./wave(okPre));               % shift seen against the original probe, Hz
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b3Prediction = table(myPrediction, round(fPre, 2), predictionNote, ...
    VariableNames = {'MyPrediction', 'MeasuredAfterPrecompensation_Hz', 'Note'});
b3Prediction
%%
% The channel moves the probe by the shift put into SatelliteDopplerShift, 
% and with both Doppler properties at 0 it moves it by nothing. Removing the 
% measured shift at the receiver leaves essentially nothing, because this 
% beat measured it exactly; a real receiver would be correcting an estimate. 
% Compare the pre-compensated case with your prediction.
%% B3 — Assertion checks

% One row per assert in B3. Pass is computed from the stored flags.
b3Checks = table( ...
    ["Measured shift matches SatelliteDopplerShift"; ...
     "Static channel adds no shift"], ...
    [string(applied) + " Hz within 1 percent"; "|f| < " + string(0.001*applied) + " Hz"], ...
    [string(round(fHat, 2)) + " Hz"; string(round(f0, 2)) + " Hz"], ...
    [okMeasure; okStatic], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b3Checks
%% B3 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Nothing later needs the channel; keep rttGeoEdge and rttLeoEdge for B4.
clear b3Shift b3Checks b3Prediction predictionNote okMeasure okStatic ...
      carrier ofdmInfo fs txGrid kDC wave t applied delaySpread chSeed makeNtn estF ...
      chOn chOff chPre rx ok fHat rxFix fRes rx0 ok0 f0 fPredicted wavePre rxPre okPre fPre myPrediction
%% B4 — The HARQ counterexample
% New words
% • Stop-and-wait: a HARQ process sends one block and waits for its ACK or 
% NACK before it sends again. Busy fraction: the share of slots that carry 
% a transmission.
% Beat-only commands
% None beyond Staging; the simulation is a loop over slots.
% Why it matters
% Each HARQ process waits a whole round trip for its answer. On the ground 
% that is a few slots, so a handful of processes keeps every slot busy. From 
% GEO the round trip is hundreds of slots long, and the toolbox allows at 
% most 32 processes, so most slots sit empty. This beat counts that occupancy 
% two ways: with the formula in Key relationships, and by simulating the processes 
% slot by slot. It counts geometry only; it does not switch HARQ feedback 
% off in the toolbox. The standard's answer for NTN, letting the network skip 
% some feedback, is a design choice described in words.
% What to look for
% • In the HARQ table: the round trip in slots for GEO and LEO, and the busy 
% fraction with 32 processes by both routes.
% Common mistakes
% Do not give a GEO link the same number of HARQ processes as a terrestrial 
% one and then wonder where the throughput went.
% 
% Do not divide by the round trip in milliseconds when the slot is not 1 ms: 
% count it in slots.
% Try it (personal exploration)
% Predict how many HARQ processes would keep the worst-case GEO transparent 
% link busy in every slot, at one 1 ms slot per process. Type it into myPrediction 
% before you run this section; the one-row table at the end reads it from 
% the round trip.

% Try it: type your prediction here (processes) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B4 — The HARQ counterexample
fprintf("B4 — The HARQ counterexample\n");   % banner title only; every number below goes into a table

orbitName = ["GEO, 10 degrees"; "LEO 600 km, 10 degrees"];
rttCase = [rttGeoEdge; rttLeoEdge];     % worst-case transparent round trips from B1, s
nRtt = ceil(rttCase/tSlot);             % round trip in whole slots

% Route 1: the formula.
busyFormula = min(nHarqMax, nRtt)./nRtt;

% Route 2: simulate nHarqMax stop-and-wait processes slot by slot.
busySim = zeros(2, 1);
for o = 1:2
    nextFree = zeros(nHarqMax, 1);      % first slot at which each process may send again
    nSlots = 10*nRtt(o);                % ten round trips of slots, enough for a steady count
    nBusy = 0;
    % Each slot: the first idle process (if any) sends, then waits one round trip.
    for s = 0:nSlots - 1
        p = find(nextFree <= s, 1);
        if ~isempty(p)
            nBusy = nBusy + 1;          % this slot carries a transmission
            nextFree(p) = s + nRtt(o);  % that process is blocked until its answer comes back
        end
    end
    busySim(o) = nBusy/nSlots;
end

% One test: the simulation agrees with the formula for both orbits.
okHarq = all(abs(busySim - busyFormula) < 0.01*busyFormula);
assert(okHarq, ...
    'The simulated busy fraction should match the formula. Look first at nRtt: both routes must use the same whole number of slots, ceil(RTT / slot), not the raw milliseconds.');

b4Harq = table(orbitName, round(rttCase*1e3, 2), nRtt, repmat(nHarqMax, 2, 1), round(100*busyFormula, 2), round(100*busySim, 2), ...
    VariableNames = {'Link', 'RTT_ms', 'RTT_slots', 'Processes', 'Busy_percent_formula', 'Busy_percent_simulated'});
b4Harq

% Put your Try-it prediction beside the number of processes that fills every GEO slot.
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b4Prediction = table(myPrediction, nRtt(1), predictionNote, ...
    VariableNames = {'MyPrediction', 'ProcessesToFillGEO', 'Note'});
b4Prediction
%%
% With 32 processes the GEO link carries a transmission in only a small share 
% of its slots, and the slot-by-slot simulation gives the same share as the 
% formula. The LEO round trip is shorter than 32 slots, so the same 32 processes 
% keep it fully busy. Compare the number that would fill every GEO slot with 
% your prediction.
%% B4 — Assertion checks

% One row per assert in B4. Pass is computed from the stored flag.
b4Checks = table("Simulated busy fraction matches the formula", ...
    listText(round(100*busyFormula, 2)) + " percent", listText(round(100*busySim, 2)) + " percent", okHarq, ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b4Checks
%% B4 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Nothing later needs the beats' values; keep c, R, and listText for the Build it checks.
clear b4Harq b4Checks b4Prediction predictionNote okHarq ...
      orbitName rttCase nRtt busyFormula busySim o nextFree nSlots nBusy s p ...
      rttGeoEdge rttLeoEdge myPrediction
%% Build it — From altitude and elevation to slant range, round trips, Doppler, and HARQ processes
% Competency: from an orbit and an elevation, compute the slant range, both 
% round trips, the Doppler a passing satellite causes, and the number of HARQ 
% processes needed to keep the link busy.
% Problem
% A LEO constellation flies at 1200 km at 7.2 km/s. A phone sees one satellite 
% at 30° elevation on its way up, on a 2 GHz carrier with 30 kHz spacing 
% (0.5 ms slots). Work out the slant range, the transparent and regenerative 
% round trips, the Doppler shift at that moment, and how many stop-and-wait 
% HARQ processes would keep every slot busy on the transparent link.
% Allowed commands
% x = value and [a b c]; + - * / and ^; sqrt(x); sind(e) and cosd(e); ceil(x). 
% R and c from Staging. The tables in the check sections and Stage 5 are given. 
% All of these are in Key code terms to remember.
% How to work
% Each stage is a code section with lines that start with %. Delete the % in 
% front of the code lines (not the comment lines), fill any ___ blank, and run 
% that section. Then run the check section under it. A check never gives the 
% answer; it tells you what to look at. When a check passes, it shows a small 
% table of what it tested: name, expected, actual, and pass.
%% Stage 1 — switch it on
% Delete the % in front of the code lines, then run this section.
% Pass: the check below prints Stage 1 OK.

% myH = 1200e3;        % altitude, m
% myV = 7.2e3;         % satellite speed, m/s
% myElev = 30;         % elevation, degrees
% myFc = 2e9;          % carrier, Hz
% mySlot = 0.5e-3;     % slot length at 30 kHz spacing, s
%% Stage 1 check (given)
if ~exist('myH','var') || ~exist('myV','var') || ~exist('myElev','var') || ~exist('myFc','var') || ~exist('mySlot','var')
    disp('Stage 1 not done: delete the % in front of the code lines above, then run that section.')
else
    % The given values must still be in place before the later stages use them.
    okStage1 = myH == 1200e3 && myV == 7.2e3 && myElev == 30 && myFc == 2e9 && mySlot == 0.5e-3;
    assert(okStage1, ...
        'Stage 1 values changed. Look first at the five lines you uncommented: 1200 km, 7.2 km/s, 30 degrees, 2 GHz, 0.5 ms.')
    stage1Checks = table("Given values", "1200e3, 7.2e3, 30, 2e9, 0.5e-3", ...
        listText([myH myV myElev myFc mySlot]), okStage1, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage1Checks
    disp('Stage 1 OK')
end
%% Stage 2 — the slant range
% Fill the blanks: the slant-range formula from Key relationships, with the 
% elevation in degrees.
% Pass: Stage 2 OK.

% myD = sqrt((R + ___)^2 - (R*cosd(___))^2) - R*sind(myElev);
%% Stage 2 check (given; the check goes through the Earth-centre angle and the law of cosines, a different route from yours)
if ~exist('myD','var')
    disp('Stage 2 not done: fill the blanks, uncomment, and run.')
else
    % Different route: the angle at the Earth's centre, then the triangle side opposite it.
    lamOracle = acosd(R*cosd(myElev)/(R + myH)) - myElev;                    % degrees
    dOracle = sqrt(R^2 + (R + myH)^2 - 2*R*(R + myH)*cosd(lamOracle));       % m
    okStage2 = abs(myD - dOracle) < 1;
    assert(okStage2, ...
        'myD is off. Look first at the units: the altitude in metres, like R, and the angles in degrees, with sind and cosd.')
    stage2Checks = table("Slant range", string(round(dOracle/1e3, 2)) + " km", string(round(myD/1e3, 2)) + " km", okStage2, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage2Checks
    disp('Stage 2 OK')
end
%% Stage 3 — predict, then the round trips
% Predict first: the transparent round trip in milliseconds. Type it into 
% myPrediction. Then fill the blanks: the transparent and regenerative round 
% trips in seconds.
% Pass: Stage 3 OK.

% myPrediction = ___;
% myRttT = ___*myD/c;
% myRttR = ___*myD/c;
%% Stage 3 check (given; the check adds one-way times leg by leg in a loop, a different route from yours)
if ~exist('myRttT','var') || ~exist('myRttR','var')
    disp('Stage 3 not done: fill the blanks, uncomment, and run.')
else
    % Different route: add one-way slant-range times, one leg at a time.
    rttTOracle = 0;
    % Transparent: phone up, down to the gateway, back up, down to the phone (feeder taken as the same length).
    for leg = 1:4
        rttTOracle = rttTOracle + dOracle/c;
    end
    rttROracle = dOracle/c + dOracle/c;   % regenerative: up and down once
    okStage3 = [abs(myRttT - rttTOracle) < 1e-9; abs(myRttR - rttROracle) < 1e-9];
    assert(okStage3(1), ...
        'myRttT is off. Look first at the path: count every slant-range leg the relayed signal travels, out to the gateway and back.')
    assert(okStage3(2), ...
        'myRttR is off. Look first at where the link ends: a regenerative satellite decodes on board.')
    if ~exist('myPrediction','var')
        myPrediction = NaN;   % no prediction line was uncommented
    end
    if isnan(myPrediction)
        predictionNote = "No prediction typed";
    else
        predictionNote = "Compare the two numbers";
    end
    stage3Prediction = table(myPrediction, round(rttTOracle*1e3, 3), predictionNote, ...
        VariableNames = {'MyPrediction_ms', 'Transparent_ms', 'Note'});
    stage3Prediction
    stage3Checks = table(["Transparent round trip"; "Regenerative round trip"], ...
        [string(round(rttTOracle*1e3, 3)) + " ms"; string(round(rttROracle*1e3, 3)) + " ms"], ...
        [string(round(myRttT*1e3, 3)) + " ms"; string(round(myRttR*1e3, 3)) + " ms"], ...
        okStage3, VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage3Checks
    disp('Stage 3 OK')
end
%% Stage 4 — Doppler and HARQ processes
% Fill the blanks: the Doppler at this elevation (the formula in Key relationships, 
% with this satellite's speed and altitude), and the number of HARQ processes 
% that keeps every slot busy on the transparent link.
% Pass: Stage 4 OK.

% myFd = myV*myFc/c*R*cosd(myElev)/(R + ___);
% myProc = ceil(___/mySlot);
%% Stage 4 check (given; the check differentiates the slant range and counts slots in a loop, a different route from yours)
if ~exist('myFd','var') || ~exist('myProc','var')
    disp('Stage 4 not done: fill the blanks, uncomment, and run.')
else
    % Different route 1: range rate by a small step in the Earth-centre angle on either side.
    rOrb = R + myH;                                                          % orbit radius, m
    dStep = 1e-4;                                                            % angle step, degrees
    dPlus = sqrt(R^2 + rOrb^2 - 2*R*rOrb*cosd(lamOracle + dStep));
    dMinus = sqrt(R^2 + rOrb^2 - 2*R*rOrb*cosd(lamOracle - dStep));
    rateOracle = (dPlus - dMinus)/(2*deg2rad(dStep))*(myV/rOrb);            % m/s, range growing with the angle
    fdOracle = myFc/c*rateOracle;                                            % on the way up the range shrinks, so this is the size
    % Different route 2: count slots until they cover the round trip.
    procOracle = 0;
    % Add one slot (one more process) until the slots reach the transparent round trip.
    while procOracle*mySlot < rttTOracle
        procOracle = procOracle + 1;
    end
    okStage4 = [abs(myFd - fdOracle) < 1; myProc == procOracle];
    assert(okStage4(1), ...
        'myFd is off. Look first at the units: speed in m/s, carrier in Hz, altitude in metres, so the result comes out in Hz.')
    assert(okStage4(2), ...
        'myProc is off. Look first at the units and the rounding: both times in seconds, and a part slot still needs a whole process.')
    stage4Checks = table(["Doppler at 30 degrees"; "Processes to fill every slot"], ...
        [string(round(fdOracle/1e3, 3)) + " kHz"; string(procOracle)], ...
        [string(round(myFd/1e3, 3)) + " kHz"; string(myProc)], ...
        okStage4, VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage4Checks
    disp('Stage 4 OK')
end
%% Stage 5 — confirm it does what it should (given)
% Run the whole script from the top (Run All), then read this table, and 
% write your interpretation in the text cell after it.

if ~exist('myD','var') || ~exist('myRttT','var') || ~exist('myFd','var') || ~exist('myProc','var')
    disp('Stage 5 needs Stages 1 to 4 first: finish them, then Run All.')
else
    % Each flag is computed from your results, so the table cannot say Pass by itself.
    buildFlags = [myD > myH && myD < myH/sind(myElev); ...
        abs(myRttT - 2*myRttR) < 1e-12; ...
        myFd > 0 && myFd < myV*myFc/c; ...
        myProc > nHarqMax];

    % One row per result: what the rule says, your value, and the computed flag.
    buildChecks = table( ...
        ["Slant range between the altitude and altitude/sin(elevation)"; "Transparent is twice regenerative"; ...
         "Doppler below the bound v*fc/c"; "More processes needed than the toolbox's 32"], ...
        ["between " + string(round(myH/1e3)) + " and " + string(round(myH/sind(myElev)/1e3)) + " km"; ...
         "ratio 2"; "< " + string(round(myV*myFc/c/1e3, 2)) + " kHz"; "> 32"], ...
        [string(round(myD/1e3, 1)) + " km"; string(round(myRttT/myRttR, 6)); string(round(myFd/1e3, 2)) + " kHz"; ...
         string(myProc)], ...
        buildFlags, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    buildChecks
end
%%
% Your interpretation (write one or two sentences here): is this link closer 
% to the GEO or the LEO-600 case in B4, and what would you change (orbit, 
% spacing, or HARQ) to keep its slots busy?
%% Build it — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Clear the check scratch: the different-route values, flags, and check
% tables. Your own my... results stay, so you can look at them while you
% do the exercises below; listText stays in case you rerun a check.
clear okStage1 stage1Checks lamOracle dOracle okStage2 stage2Checks ...
      rttTOracle leg rttROracle okStage3 stage3Checks stage3Prediction predictionNote ...
      rOrb dStep dPlus dMinus rateOracle fdOracle procOracle okStage4 stage4Checks ...
      buildFlags buildChecks
%% Follow-on exercises
% These go one step past the beats above: new values, a diagnosis, or an explanation. 
% Copying a code block from above and changing one number will not answer them, 
% because each one asks for a reason as well as a value. You may use MATLAB 
% as a calculator in a new section of your own. Write your answers on the Your 
% answer lines. Your teacher has model answers.
% E1 — New values (B1 and B4)
% Take the worst-case GEO link with a regenerative payload instead. What is 
% its round trip, how many 1 ms slots is that, and what share of slots can 
% 32 stop-and-wait processes keep busy? Halving the round trip doubles the 
% share: say why that is still far from enough, and how many processes would 
% keep every slot busy.
% 
% Your answer:
% E2 — New values (B1)
% A medium-Earth-orbit (MEO) satellite flies at 8000 km. Work out its slant 
% range at 10° elevation and its transparent round trip in milliseconds. 
% Is it nearer the LEO or the GEO case, and by what factor?
% 
% Your answer:
% E3 — Diagnosis (B2)
% A classmate's Doppler curve over a pass is zero at the horizon and largest 
% straight overhead. What did they most likely write wrong in the formula, 
% and how would the range-rate route from B2 have caught it?
% 
% Your answer:
% E4 — Explanation (B3)
% Many phones share one satellite beam, each at a different place, so each 
% sees a different Doppler and round trip. Explain why each phone must pre-compensate 
% its own uplink before transmitting, instead of the base station correcting 
% all of them after reception. What is left over for the base station to 
% handle?
% 
% Your answer:
% E5 — New values (B4)
% The same worst-case GEO transparent link runs at 30 kHz spacing (0.5 ms 
% slots). How many slots is the round trip, and what share can 32 processes 
% keep busy? Why does a faster numerology make the problem worse, not better?
% 
% Your answer:
% E6 — Explanation (terms)
% nrTDLChannel has two Doppler properties: MaximumDopplerShift and SatelliteDopplerShift. 
% Say what each one models, which one the phone's pre-compensation can remove, 
% and why the other one cannot be removed the same way.
% 
% Your answer:
%% Recap — Signals from Orbit (album track 13)
% From orbit, the same physics gives huge numbers. The slant range at the 
% edge of coverage sets the worst case: four slant ranges for a transparent 
% satellite, two for a regenerative one. A LEO pass sweeps the Doppler through 
% tens of kilohertz and back through zero. The toolbox adds that common shift 
% through SatelliteDopplerShift on an NTN delay profile. The phone removes 
% what the geometry predicts before it transmits, and long round trips leave 
% stop-and-wait HARQ mostly idle.
% Key relationships
% $$d(\varepsilon) = \sqrt{(R+h)^2 - R^2\cos^2\varepsilon} - R\sin\varepsilon,\qquad 
% \mathrm{RTT} = \frac{4d}{c}\ \text{or}\ \frac{2d}{c},\qquad f_D = \frac{v f_c}{c}\cdot\frac{R\cos\varepsilon}{R+h}$$
% What this means in practice
% • Use the edge of coverage, not the altitude, for the worst case, and c 
% = 299 792 458 m/s.
% 
% • Count four legs for a transparent payload and two for a regenerative one.
% 
% • Set SatelliteDopplerShift from the geometry of the pass.
% 
% • Pre-compensate at the transmitter from GNSS and the ephemeris; leave only 
% the remainder for the receiver.
% 
% • Count HARQ round trips in slots, not milliseconds.
% 
% • You computed a slant range, both round trips, a Doppler shift, and the 
% HARQ processes a LEO-1200 link would need.
% 
% • Retrieval prompt (answer in one line; the answer key has it): from album 
% track 12 (track12/track12_how_far_demo), why does a round-trip range need 
% no shared clock between the phone and the base station?
% 
% • Next in the album: track14 (Mirror Image).
%% Review — self-check
% Do this without looking at the header. Scroll down so the top of the file 
% is out of sight, then write from memory, in your own words.
% 
% First, each of the seven key ideas, one line each. Then, for each command 
% you write yourself (listed below by name only), its purpose, its inputs, and 
% its outputs.
% 
% When you have written all you can, scroll up to Key ideas to remember and 
% Key code terms to remember and compare. Mark anything you missed or got wrong, 
% and reread the beat where it was used. The commands you read, the families 
% of helpers, and the short lists at the start of each beat are not part of 
% this review: tick them against their lists, or look one up when you meet it 
% again. Nothing in this section is checked by the script.
% My key ideas
% 1.
% 
% 2.
% 
% 3.
% 
% 4.
% 
% 5.
% 
% 6.
% 
% 7.
% Commands I write (purpose; inputs; outputs)
% • x = value and [a b c]:
% 
% • + - * / and ^:
% 
% • sqrt(x):
% 
% • sind(e) and cosd(e):
% 
% • ceil(x):
% What I missed, and where to reread it
% 
