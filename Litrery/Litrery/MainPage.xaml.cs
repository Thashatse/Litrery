using Litrery.DataAccess;

namespace Litrery;

public partial class MainPage : ContentPage
{
    private readonly VehicleRepository _repo = new();

    public MainPage()
    {
        InitializeComponent();
        Loaded += OnPageLoaded;
    }

    private async void OnPageLoaded(object? sender, EventArgs e)
    {
        LoadingIndicator.IsVisible = true;
        LoadingIndicator.IsRunning = true;

        try
        {
            var vehicles = await _repo.ReadVehicles();
            VehicleList.ItemsSource = vehicles;
        }
        catch (Exception ex)
        {
            await DisplayAlertAsync("Error", "Failed to load Vehicles", "OK");
        }
        finally
        {
            LoadingIndicator.IsRunning = false;
            LoadingIndicator.IsVisible = false;
        }
    }

    private async void OnAddVehicleClicked(object? sender, EventArgs e)
    {
        // Wire up to add vehicle page later
        await DisplayAlertAsync("Coming soon", "Add vehicle form goes here", "OK");
    }
}