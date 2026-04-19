using Azure.Identity;
using Litrery.Resources;
using Microsoft.Azure.Cosmos;

namespace Litrery.DataAccess;

public class DocumentDbService
{
    private readonly Database _database;

    public DocumentDbService()
    {
        var client = new CosmosClient(
            accountEndpoint: AppConsts.DOCUMENT_DB_ENDPOINT,
            authKeyOrResourceToken: AppConsts.DOCUMENT_DB_KEY,
            new CosmosClientOptions 
            { 
                ConnectionMode = ConnectionMode.Direct,
            }
        );
        
        _database = client.GetDatabase(AppConsts.DOCUMENT_DB_NAME);
    }

    public Container GetVehiclesContainer()
    {
        return _database.GetContainer("Vehicles");
    }
}