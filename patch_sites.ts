import fs from 'fs';
const path = 'lib/features/preferences/sites_screen.dart';
let code = fs.readFileSync(path, 'utf8');

const oldBottom = `      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ctrl.error != null) ...[ErrorLine(ctrl.error!), const SizedBox(height: JmSpace.x3)],
          PrimaryButton(
            label: 'Find matching jobs',
            busyLabel: 'Starting search…',
            busy: ctrl.starting,
            large: true,
            icon: Icons.search_rounded,
            onPressed: ctrl.canStart ? () => _start(context) : null,
          ),
        ],
      ),`;

const newBottom = `      bottom: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: JmSpace.x2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ctrl.error != null) ...[ErrorLine(ctrl.error!), const SizedBox(height: JmSpace.x3)],
              PrimaryButton(
                label: 'Find matching jobs',
                busyLabel: 'Starting search…',
                busy: ctrl.starting,
                large: true,
                icon: Icons.search_rounded,
                onPressed: ctrl.canStart ? () => _start(context) : null,
              ),
              const SizedBox(height: JmSpace.x2),
              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text('Skip for now', style: context.type.meta),
              ),
            ],
          ),
        ),
      ),`;

code = code.replace(oldBottom, newBottom);
fs.writeFileSync(path, code);
console.log("Patched SitesScreen");
