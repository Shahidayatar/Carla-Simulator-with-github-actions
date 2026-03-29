import carla

# Connect to the CARLA simulator
client = carla.Client('localhost', 2000)
client.set_timeout(20.0)  # seconds

try:
    # Get the world
    world = client.get_world()
    print(f"Connected to CARLA. Current map: {world.get_map().name}")

    # Spawn a test vehicle
    blueprint_library = world.get_blueprint_library()
    vehicle_bp = blueprint_library.filter('vehicle.tesla.model3')[0]

    # Spawn point (use a random available spawn point)
    spawn_point = world.get_map().get_spawn_points()[0]

    vehicle = world.try_spawn_actor(vehicle_bp, spawn_point)
    if vehicle:
        print(f"Spawned vehicle: {vehicle.type_id} at {spawn_point.location}")       
        # Destroy vehicle after 5 seconds
        import time
        time.sleep(5)
        vehicle.destroy()
        print("Vehicle destroyed.")
    else:
        print("Failed to spawn vehicle.")

except Exception as e:
    print(f"Error connecting to CARLA: {e}")