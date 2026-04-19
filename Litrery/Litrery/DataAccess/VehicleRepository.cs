using System.Net;
using Litrery.Models;
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.Cosmos.Linq;

namespace Litrery.DataAccess;

public class VehicleRepository
{
    private DocumentDbService _docDbService = new();

    public async Task<List<Vehicle>> ReadVehicles()
    {
        try
        {
            var container = _docDbService.GetVehiclesContainer();
            
            // Use LINQ for better readability; the SDK handles the conversion to SQL
            using var feed = container.GetItemLinqQueryable<Vehicle>()
                .ToFeedIterator();

            List<Vehicle> items = [];
            while (feed.HasMoreResults)
            {
                var response = await feed.ReadNextAsync();
                items.AddRange(response);
            }

            return items;
        }
        catch (Exception e)
        {
            Console.WriteLine(e);
            throw;
        }
    }


    public async Task<Vehicle?> ReadVehicle(string id, string vehicleIdentificationNumber)
    {
        try
        {
            var response = await _docDbService.GetVehiclesContainer().ReadItemAsync<Vehicle>(
                id: id,
                partitionKey: new PartitionKey(vehicleIdentificationNumber)
            );

            return response?.StatusCode == HttpStatusCode.OK
                ? response?.Resource
                : throw new Exception($"Upsert failed. HTTP Response: {response?.StatusCode}");
        }
        catch (Exception e)
        {
            Console.WriteLine(e);
            throw;
        }
    }

    public async Task<Vehicle> UpsertVehicle(Vehicle vehicle)
    {
        try
        {
            var response = await _docDbService.GetVehiclesContainer().UpsertItemAsync(
                item: vehicle,
                partitionKey: new PartitionKey(vehicle.VehicleIdentificationNumber)
            );

            return response?.StatusCode == HttpStatusCode.OK
                ? response.Resource
                : throw new Exception($"Upsert failed. HTTP Response: {response?.StatusCode}");
        }
        catch (Exception e)
        {
            Console.WriteLine(e);
            throw;
        }
    }
}