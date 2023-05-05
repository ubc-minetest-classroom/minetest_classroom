function mc_teacher.shutdown_server(reconnect)
    minetest.request_shutdown("Server is undergoing a scheduled restart. Please try to reconnect after one minute.",reconnect,0)
end