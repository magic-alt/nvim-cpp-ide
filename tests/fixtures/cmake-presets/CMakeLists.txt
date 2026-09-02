cmake_minimum_required(VERSION 3.20)
project(task_engine_fixture C)

enable_testing()
add_executable(task_engine_hello main.c)
add_test(NAME task_engine_hello COMMAND task_engine_hello)

add_custom_target(lint
  COMMAND ${CMAKE_COMMAND} -E echo "lint ok"
)
add_custom_target(format
  COMMAND ${CMAKE_COMMAND} -E echo "format ok"
)
