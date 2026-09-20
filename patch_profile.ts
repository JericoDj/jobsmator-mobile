import fs from 'fs';
const path = 'lib/features/profile/profile_screen.dart';
let code = fs.readFileSync(path, 'utf8');

const oldSignOut = `          DangerButton(label: 'Sign out', onPressed: auth.signOut),`;

const newSignOut = `          DangerButton(
            label: 'Sign out',
            onPressed: () async {
              try {
                context.read<JobCatalogProvider>().clear();
                context.read<RunProvider>().clear();
                context.read<PreferencesProvider>().clear();
                context.read<SubscriptionProvider>().clear();
                await auth.signOut();
              } catch (e) {
                // ignore
              }
            },
          ),`;

code = code.replace(oldSignOut, newSignOut);
fs.writeFileSync(path, code);
console.log("Patched ProfileScreen");
