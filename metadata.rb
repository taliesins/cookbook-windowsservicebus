name             'windowsservicebus'
maintainer       'Taliesin Sisson'
maintainer_email 'taliesins@yahoo.com'
license          'All rights reserved'
description      'Installs/Configures windowsservicebus'
long_description 'Installs/Configures windowsservicebus'

version          '0.1.0'

depends 'role-db'
depends 'webpi'
depends 'database'
depends 'windows', '>= 1.2.6'
depends 'ssl_certificate', '~> 1.9.0'