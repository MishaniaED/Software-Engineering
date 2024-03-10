workspace {
    name "Сервис поиска попутчиков"
    description "Сервис, помогающий людям найти попутчиков для совместных поездок"

    # включаем режим с иерархической системой идентификаторов
    !identifiers hierarchical

    !docs documentation
    !adrs decisions

    # Модель архитектуры
    model {
        # Настраиваем возможность создания вложенных груп
        properties { 
            structurizr.groupSeparator "/"
        }

        # Описание компонент модели
        user    = person "Пользователь"
        route   = softwareSystem "Система построения маршрутов"
        api     = softwareSystem "API" {
            description "Серверная часть приложения"
            tags "backend"

            user_service = container "User service" {
                description "Сервис управления пользователями"
            }

            route_service = container "Route service" {
                description "Сервис управления маршрутами"
            }

            trip_service = container "Trip service" {
                description "Сервис управления поездками"
            }

            group "Слой данных" {
                user_database = container "User Database" {
                    description "База данных с пользователями"
                    technology "PostgreSQL 15"
                    tags "database"
                }

                user_cache = container "User Cache" {
                    description "Кеш пользовательских данных для ускорения аутентификации"
                    technology "PostgreSQL 15"
                    tags "database"
                }

                route_database = container "Route Database" {
                    description "База данных для хранения информации о маршрутах"
                    technology "MongoDB 5"
                    tags "database"
                }
            }

            user_service -> user_cache "Получение/обновление данных о пользователях" "TCP 6379"
            user_service -> user_database "Получение/обновление данных о пользователях" "TCP 5432"
            user_service -> trip_service "Получение данных о поездке" "TCP 1580"

            route_service -> route_database "Получение данных о маршрутах" "TCP 27018"

            trip_service -> route_service "Получение маршрута" "TCP 7018"

            user -> user_service "Регистрация нового пользователя / ауентификация" "REST HTTP:8080"
            route -> route_service "Обновление данных о маршрутах" "REST HTTP:8080"
        }

        user -> api "Запросы к API"
        route -> api "Получение актуальных данных о маршрутах"

        deploymentEnvironment "Production" {
            deploymentNode "User Server" {
                containerInstance api.user_service
            }

            deploymentNode "Route Server" {
                containerInstance api.route_service
                properties {
                    "cpu" "4"
                    "ram" "256Gb"
                    "hdd" "4Tb"
                }
            }

            deploymentNode "Trip Server" {
                containerInstance api.trip_service
            }

            deploymentNode "databases" {
     
                deploymentNode "Database Server 1" {
                    containerInstance api.user_database
                }

                deploymentNode "Database Server 2" {
                    containerInstance api.route_database
                    instances 3
                }

                deploymentNode "Cache Server" {
                    containerInstance api.user_cache
                }
            }
            
        }
    }

    views {
        themes default

        properties { 
            structurizr.tooltips true
        }


        !script groovy {
            workspace.views.createDefaultViews()
            workspace.views.views.findAll { it instanceof com.structurizr.view.ModelView }.each { it.enableAutomaticLayout() }
        }


        dynamic api "UC01" "Добавление нового пользователя" {
            autoLayout
            user -> api.user_service "Создать нового пользователя (Swagger POST /user)"
            api.user_service -> api.user_database "Сохранить данные о пользователе" 
        }

        dynamic api "UC02" "Поиск пользователя по логину или по маске имя фамилия" {
            autoLayout
            user -> api.user_service "Найти пользователя (GET /user /string)"
        }

        dynamic api "UC03" "Создание маршрута" {
            autoLayout
            route -> api.route_service "Создать новый маршрут (POST /route)"
            api.route_service -> api.route_database "Сохранить данные о маршруте"
        }

        dynamic api "UC04" "Получение маршрутов пользователя" {
            autoLayout
            user -> api.user_service "Найти пользователя (GET /user)"
            api.user_service -> api.trip_service "Найти поездки пользователя (GET /trip)"
            api.trip_service -> api.route_service "Найти маршруты пользователя (GET /route)"
        }

        dynamic api "UC05" "Создание поездки" {
            autoLayout
            user -> api.user_service "Создать поездку (POST /api)"
            api.user_service -> api.trip_service "Создать поездку (POST /trip)"
            api.trip_service -> api.route_service "Создать маршрут (POST /route)"
            api.route_service -> api.route_database "Сохранить данные о созданном маршруте"
        }

        dynamic api "UC06" "Подключение пользователей к поездке" {
            autoLayout
            user -> api.user_service "Подключить к поездке (POST /user /trip)"
            api.user_service -> api.trip_service "Подключить пользователя к поездке (POST /user /trip)"
        }

        dynamic api "UC07" "Получение информации о поездке" {
            autoLayout
            user -> api.user_service "Найти информацию о поездке (GET /trip)"
            api.user_service -> api.trip_service "Получить информацию о поездке (GET /trip)"
            api.trip_service -> api.route_service "Получить информацию о маршруте (GET /route)"
            api.route_service -> api.route_database "Получить информацию о маршруте (GET /route)"
        }


        styles {
            element "database" {
                shape cylinder
            }
        }
    }
}