import fs from 'fs';
const path = 'lib/features/preferences/interests_screen.dart';
let code = fs.readFileSync(path, 'utf8');

const oldBottom = `      bottom: PrimaryButton(
        label: 'Next: choose job sites',
        large: true,
        icon: Icons.arrow_forward_rounded,
        onPressed: ctrl.canContinue ? () => context.go(AppRoutes.sites) : null,
      ),`;

const newBottom = `      bottom: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: JmSpace.x2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrimaryButton(
                label: 'Next: choose job sites',
                large: true,
                icon: Icons.arrow_forward_rounded,
                onPressed: ctrl.canContinue ? () => context.go(AppRoutes.sites) : null,
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
console.log("Patched InterestsScreen");
