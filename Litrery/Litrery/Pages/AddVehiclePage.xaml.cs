using Litrery.DataAccess;
using Litrery.Models;

namespace Litrery.Pages;

public partial class AddVehiclePage : ContentPage
{
    private readonly VehicleRepository _repo = new();
    
    public AddVehiclePage()
    {
        InitializeComponent();
    }
    
    private async void OnCancelClicked(object? sender, EventArgs e)
    {
        await Navigation.PopModalAsync();
    }

    
    private async void OnSaveClicked(object? sender, EventArgs e)
    {
        if (string.IsNullOrWhiteSpace(ModelEntry.Text) || 
            string.IsNullOrWhiteSpace(MakeEntry.Text) || 
            string.IsNullOrWhiteSpace(VinEntry.Text))
        {
            await DisplayAlertAsync("Validation", "Make and model are required", "OK");
            return;
        }

        var vehicle = new Vehicle
        {
            Make = MakeEntry.Text?.Trim() ?? string.Empty,
            Model = ModelEntry.Text?.Trim() ?? string.Empty,
            Year = YearEntry.Text?.Trim() ?? string.Empty,
            Color = ColorEntry.Text?.Trim() ?? string.Empty,
            RegistrationNumber = RegistrationEntry.Text?.Trim() ?? string.Empty,
            VehicleIdentificationNumber = VinEntry.Text?.Trim() ?? string.Empty,
            Odometer = int.TryParse(OdometerEntry.Text, out var odo) ? odo : 0
        };

        try
        {
            await _repo.UpsertVehicle(vehicle);
            await Navigation.PopModalAsync();
        }
        catch (Exception ex)
        {
            await DisplayAlertAsync("Error", "Failed to create Vehicle", "OK");
        }
    }
}