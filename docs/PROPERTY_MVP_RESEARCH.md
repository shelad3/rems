# Property Creation MVP — Research & Plan

## Goal

Give owners (and admins) a real, end-to-end flow to create a property, optionally add units, and assign people to it (owner + caretaker). This is the first step toward a system where owners can manage ROIs, units, rent, and caretaker employment without admin intervention.

## Current state (as researched)

- **Data model**: `PropertyModel` lives in Firestore `properties` and carries only counters (`totalUnits`, `availableUnits`). Units are separate documents in `units` keyed by `propertyId` (FK), not a subcollection.
- **Who can create**: Firestore rules already allow `owner`/`manager`/`admin` to create properties and units. The old UI, however, only had a basic add-property form with no units and no assignment.
- **Roles**: `owner`, `manager`, `caretaker`, `tenant`, `admin`. Internal helpers already used `managerId` on a property to know the caretaker/manager assigned to it.
- **Auth**: super-admin is fixed at `sheldonramu8@gmail.com` (resolves to role `admin` unconditionally).
- **Wallet & payments**: rent flows through M-Pesa; deposits credit `wallets/{uid}`; unit occupancy (`occupied`) controls `availableUnits` counters.

## Decisions for the MVP

### Required fields (property)
- `name`, `location` (town/area), `county`
- property type (dropdown: apartment, multiplex, hostel, mixed-use, commercial, townhouse, bedsitter block, other)
- owner (admin-only picker; otherwise current user)
- property created with `status: active`

### Optional fields (property)
- description
- cover photo (uploaded to Firebase Storage via `FirebaseService.uploadFile`)
- amenities (multi-select chips: water, electricity, parking, security, gym, swimming pool, laundry, WiFi, furnished, elevator, borehole, garbage collection)
- caretaker (dropdown from users with role `caretaker`; admin + owner can assign)

### Units (optional at creation, always manageable later)
- bulk "Add Units" on the property form (count + default rent/deposit), auto-numbered `1..N`
- dedicated Add Units screen for appending units with prefix (e.g. `B` => `B1, B2, ...`), type, bedrooms, rent, deposit
- Edit Unit screen: rename, type, bedrooms, rent, deposit, occupancy toggle
- occupancy toggle adjusts `availableUnits` on the property by ±1
- delete unit (owner/admin; reduces counters)

### Access & management
- Owners/`manager`/admins see all units for a property plus FAB "Add Unit" and "Edit Property" (owner/caretaker assignment lives in the edit form)
- Non-owners (tenants, guests) only see `availableUnits` and can Request Access
- Caretakers see only their assigned properties (`getPropertiesByCaretaker` = `managerId == uid`) and can operate on units but not delete

## Repository API (added/used)

- `PropertyRepository.createProperty`, `updateProperty`, `updateUnitsCount(propertyId, total, available)`
- `PropertyRepository.createUnit`, `updateUnit`, `deleteUnit`, `getUnitsByProperty`, `getAvailableUnits`
- `PropertyRepository.assignCaretaker(propertyId, caretakerId)` (writes `managerId` + `caretakerId`)
- `PropertyRepository.assignOwner(propertyId, ownerId)`
- `PropertyRepository.getPropertiesByOwner`, `getPropertiesByManager`, `getPropertiesByCaretaker`
- `PropertyModel` gained `caretakerId` (mirrors legacy `managerId`)

## Audit logging

Every write logs to `audit_logs`: `property_created`, `property_updated`, `units_created`, `unit_updated`, `unit_deleted` with actor + target + metadata.

## Firestore rules (MVP)

- `units`: read public; create if owner/admin; update if property owner, admin, or assigned caretaker; delete if admin or property owner
- `properties`: update by property owner or admin (covers caretaker/owner assignment via the edit form)

## Open items / follow-ups

- Caretaker "employment" (role + status change + onboarding) not yet a first-class action; for now assigning a caretaker simply links the property via `managerId`/`caretakerId`
- Unit-level details like lease linkage, utilities/meter readings, and photos-on-units remain future work
- Property listing/compare (rental risk score, ROI) unaffected by this MVP
- Real M-Pesa callback settle path cannot be verified end-to-end without a sandbox test phone + valid callback reachability

## Files touched

- `lib/features/properties/screens/add_property_screen.dart` — full create/edit form
- `lib/features/properties/screens/add_unit_screen.dart`, `edit_unit_screen.dart` — unit bulk-add and edit
- `lib/features/properties/screens/unit_detail_screen.dart` — manage view + add/edit/delete
- `lib/data/models/property_model.dart`, `lib/data/repositories/property_repository.dart`
- `lib/features/caretaker/screens/caretaker_units_screen.dart` — assigned-only filter
- `lib/features/owner/screens/owner_properties_screen.dart` — entry to manage view
- `firestore.rules`