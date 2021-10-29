variable "DEFAULT_TAG" {
  default = "recordr:local"
}

// Special target: https://github.com/docker/metadata-action#bake-definition
target "docker-metadata-action" {
  tags = ["${DEFAULT_TAG}"]
}

// Default target if none specified
group "default" {
  targets = ["image-local"]
}

target "image" {
  inherits = ["docker-metadata-action"]
}

target "image-local" {
  inherits = ["image"]
  output = ["type=docker"]
}
# TODO
target "image-all" {
  inherits = ["image"]
  platforms = [
    "linux/amd64"
//    "linux/arm/v6",
#    "linux/arm/v7",
//    "linux/arm64",
#    "linux/arm64/v8",
#    "linux/ppc64le",
#    "linux/riscv64",
#    "linux/s390x"
  ]
}
