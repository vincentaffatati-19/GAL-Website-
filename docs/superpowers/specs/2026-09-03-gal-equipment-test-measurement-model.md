# GAL Equipment Test & Measurement Model

Status: APPROVED / LOCKED
Date: 2026-09-03
Applies to: GAL Lab testing, fitting sessions, equipment evidence, Equipment Knowledge, AI Fitting, Buyers Guides, Equipment Intelligence, and longitudinal outcome analysis.

## 1. Governing Principle

**GAL conclusions are reproducible derivatives of preserved physical samples, exact configurations, governed protocols, qualifying raw measurements, and documented test context. Tests describe the conditions under which equipment behaved a certain way; GAL does not automatically generalize beyond those conditions.**

Raw measurements are preserved separately from derived conclusions.

## 2. Canonical Test Structure

GAL uses the following conceptual hierarchy:

`Test Program -> Test Session -> Physical Sample -> Configuration -> Trial/Shot -> Raw Measurement -> Aggregated Result -> Derived Equipment Characteristic`

Each layer has a distinct purpose and provenance responsibility.

## 3. Test Program

A Test Program represents a governed testing methodology or protocol.

It should preserve:
- test_program_id;
- category and purpose;
- protocol name;
- protocol version;
- qualifying equipment categories;
- required instrumentation;
- calibration requirements;
- test-subject requirements;
- environmental controls;
- trial inclusion/exclusion rules;
- aggregation method;
- outlier policy;
- minimum sample/trial requirements;
- derived-characteristic rules;
- approval/effective dates;
- superseded protocol relationship when applicable.

Changes to material testing methodology create a new protocol version rather than rewriting prior test history.

## 4. Test Session

A Test Session is a specific execution of a Test Program.

It should preserve:
- test_session_id;
- test_program/version;
- date/time;
- test location;
- operator/tester;
- instrumentation/device identifiers;
- device firmware/software version when material;
- calibration state;
- environment;
- indoor/outdoor state;
- turf/surface where relevant;
- ball model and ball condition when relevant;
- session notes;
- quality-control state.

## 5. Physical Sample

GAL distinguishes the product model from the actual physical item tested.

A Physical Sample may preserve:
- sample_id;
- canonical product/variant identity;
- serial number or lot identifier when available/permitted;
- acquisition source;
- manufacturer-provided vs GAL-purchased vs fitting-cart vs other source;
- retail-production / prototype / tour-only / used / other status;
- condition and wear;
- received date;
- sample-specific measured specs;
- sample notes;
- disposition/status.

Manufacturer-supplied equipment does not receive different analytical treatment, but provenance is retained for transparency and auditability.

## 6. Exact Test Configuration

Every test must preserve the actual configuration used rather than relying only on product-family identity.

Configuration may include, where relevant:
- head/variant;
- stated/measured loft;
- adapter/hosel setting;
- movable-weight setting;
- shaft model;
- shaft flex;
- shaft weight/profile;
- playing length;
- lie;
- grip;
- swing weight or total weight where available;
- iron/set member;
- wedge loft/bounce/grind;
- putter hosel/head/length/lie/loft/grip;
- ball model;
- other category-specific settings.

Configuration provenance must be retained.

## 7. Test Subject / Delivery Source

GAL distinguishes test modes and does not assume that all test evidence has the same generalizability.

### Controlled / Robot
Best suited to isolating equipment behavior under repeatable delivery conditions.

### Human Controlled
Useful when real delivery, turf interaction, feel, or human strike variability matters, but requires explicit variability controls.

### Golfer Fitting / Field Observed
Useful for golfer-specific fit, real-world performance, and longitudinal outcome evidence. It does not automatically establish a universal equipment characteristic.

Test-subject records should preserve only the context needed for analysis, such as:
- subject/tester ID;
- handedness;
- speed band;
- relevant delivery characteristics;
- test qualification/role;
- anonymized or privacy-safe context where appropriate.

## 8. Trial / Shot

Each qualifying individual trial is preserved where the test method requires trial-level evidence.

A trial may preserve:
- trial_id;
- sequence/time;
- sample/configuration;
- subject/delivery source;
- intended protocol condition;
- strike location when available;
- delivery variables when available;
- validity state;
- exclusion state and reason;
- raw instrument references.

## 9. Raw Measurement Preservation

Raw measurement data is preserved separately from aggregation and interpretation.

For launch-monitor testing, fields may include when supported by the device:
- club speed;
- ball speed;
- smash factor;
- launch angle;
- spin rate;
- carry distance;
- total distance;
- peak height;
- landing angle;
- attack angle;
- dynamic loft;
- club path;
- face angle;
- face-to-path;
- impact location;
- horizontal/vertical dispersion measures;
- other device-supported metrics.

Other GAL lab protocols may preserve category-specific raw measurements such as friction, compression, deflection, dimensional, mass, balance, face-response, or turf-interaction measurements.

## 10. Aggregated Results

Aggregated results are generated from qualifying trials under the applicable protocol version.

They may include:
- mean/median;
- standard deviation/variance;
- percentile ranges;
- dispersion patterns;
- strike-zone performance;
- consistency metrics;
- normalized metrics;
- subgroup/context results;
- sample-size count;
- excluded-trial count;
- aggregation methodology version.

GAL must not combine materially different testing contexts merely to create a single simpler number.

## 11. Derived Equipment Characteristics

GAL-derived equipment characteristics are produced from qualifying measurements/results using a governed, versioned derivation method.

Examples may include:
- launch tendency;
- spin tendency;
- forgiveness/stability class;
- directional-bias class;
- face/strike consistency;
- turf-interaction profile;
- stopping profile;
- feel-related measured proxy where validated.

Every derived characteristic must reference:
- supporting raw/aggregate evidence;
- test context;
- applicable product/configuration;
- derivation methodology/version;
- effective date;
- evidence/claim state.

If methodology changes, GAL should be able to recompute a new derived result from preserved raw measurements without rewriting the historical derivation.

## 12. Context-Specific Equipment Behavior

GAL preserves context dimensions that can materially affect observed equipment behavior.

Examples include:
- swing-speed band;
- delivery pattern;
- attack-angle band;
- strike location/zone;
- ball type;
- environment;
- equipment configuration;
- turf/surface;
- human vs robot test mode.

A product may legitimately have different derived behavior across different contexts.

GAL therefore does not require a single universal label such as `spin = low` when evidence supports a more context-specific conclusion.

## 13. Repeated Tests and Conflicting Results

Repeated tests are preserved as separate evidence rather than blindly averaged together.

GAL may combine results only when the governing methodology establishes that the tests are sufficiently comparable.

When results conflict, GAL should:
- retain each qualifying result;
- identify material differences in sample/configuration/context/protocol;
- apply an approved reconciliation or meta-analysis method when available;
- otherwise preserve the disagreement or use Unknown / Insufficient Evidence.

## 14. Outliers and Excluded Trials

**Raw trials are never silently deleted because they make a product look better or worse.**

Excluded trials remain preserved with an explicit reason.

Representative exclusion reasons may include:
- instrument error;
- known misread;
- protocol violation;
- invalid delivery outside the protocol window;
- foreign object/contact;
- corrupted record;
- invalid test setup.

The governing protocol determines whether a trial qualifies.

## 15. Environment and Instrument Context

Tests preserve relevant environmental and device context, including where material:
- temperature;
- humidity;
- altitude/barometric pressure;
- wind;
- indoor/outdoor;
- surface/turf;
- ball condition;
- device/calibration state;
- firmware/software version;
- normalization settings.

GAL should not compare or normalize results across environments unless a governed methodology supports doing so.

## 16. Generalization Constraint

A test establishes what happened under the tested conditions.

A result from one golfer, one speed band, one strike pattern, one shaft, or one environment must not automatically be generalized to all golfers or configurations.

Equipment Knowledge should preserve the scope of applicability for each derived characteristic.

## 17. Relationship to Equipment Knowledge and AI Fitting

Qualifying derived equipment characteristics may be promoted into the GAL Equipment Knowledge Layer under the approved source-governance process.

AI Fitting may use those characteristics only when:
- they are Active/promoted;
- they meet the required evidence sufficiency for the target characteristic;
- their context is sufficiently compatible with the golfer/fitting target;
- no material unresolved conflict disqualifies the evidence.

## 18. Locked Decisions

The following decisions are approved and locked:

1. Raw measurement is stored separately from derived conclusion.
2. Testing follows `Program -> Session -> Sample -> Configuration -> Trial -> Raw Measurement -> Aggregated Result -> Derived Characteristic`.
3. Physical samples are distinct from product identities.
4. Exact tested configurations are preserved.
5. Robot, human-controlled, and golfer/field tests are distinct evidence modes.
6. Golfer-specific evidence does not automatically become universal equipment truth.
7. Repeated tests are preserved and not blindly averaged.
8. Test context is part of the evidence.
9. Excluded trials remain stored with explicit reasons.
10. Manufacturer-provided sample provenance is retained without changing analytical treatment.
11. Methodology is versioned and historical derivations remain reproducible.
12. GAL does not generalize beyond the evidence-supported test context without a governed methodology.

No production schema changes are authorized by this design document alone.
