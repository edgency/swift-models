add_executable(Autoencoder1D
  main.swift)
target_link_libraries(Autoencoder1D PRIVATE
  Datasets
  ModelSupport)


install(TARGETS Autoencoder1D
  DESTINATION bin)
