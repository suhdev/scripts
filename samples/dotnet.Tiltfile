load('ext://helm_resource', 'helm_resource', 'helm_repo')

helm_repo('bitnami', 'https://charts.bitnami.com/bitnami',
          labels=['helm_repos'])
helm_repo('dapr', 'https://dapr.github.io/helm-charts/',
          labels=['helm_repos'])

local_resource('nuget-build',
               cmd='./scripts/pack-and-publish.sh',
               labels=['init-scripts'])

local_resource('services-build',
               cmd='./scripts/build-images.sh',
               labels=['init-scripts'])

helm_resource('postgresql', 'bitnami/postgresql',
              flags=['-f', './k8s/postgres-values.yaml'],
              port_forwards=['5432:5432'],
              namespace='newdawn',
              labels=['storage'])

helm_resource('mongodb', 'bitnami/mongodb',
              flags=['-f', './k8s/mongodb-values.yaml'],
              port_forwards=['27017:27017'],
              namespace='newdawn',
              labels=['storage'])

helm_resource('redis', 'bitnami/redis',
              port_forwards=['6379:6379'],
              namespace='newdawn',
              labels=['cache'])

helm_resource('rabbitmq', 'bitnami/rabbitmq',
              port_forwards=['5672:5672'],
              namespace='newdawn',
              labels=['messaging'])

helm_resource('dapr-nd', 'dapr/dapr',
              namespace='newdawn',
              labels=['runtime'])

k8s_yaml(['k8s/namespace.yaml', 'k8s/service.yaml'])
