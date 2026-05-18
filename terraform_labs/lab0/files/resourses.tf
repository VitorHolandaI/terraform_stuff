resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

resource "docker_image" "redis" {
  name         = "redis:latest"
  keep_locally = false
}

resource "docker_network" "private_network" {
  name = "private_mine_mine_mine_network"
}

resource "docker_container" "redis" {
  image = docker_image.redis.image_id
  name  = "tutorial_redis_obsidian"
  networks_advanced {
    name = "private_mine_mine_mine_network"
  }
  ports {
    internal = 6479
    external = 8982
  }
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "tutorial"
  networks_advanced {
    name = "private_mine_mine_mine_network"
  }

  ports {
    internal = 90
    external = 8000
  }
}
