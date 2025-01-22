package utils;

import java.util.ArrayList;
import java.util.List;

public class service_cleaner {
    public static void main(String[] args) {

        String application = args[0];
        List<String> services = new ArrayList<>();

        // Add all services from command line args (skipping the application name)
        for (int i = 1; i < args.length; i++) {
            services.add(args[i]);
        }

        List<String> cleanedServices = cleanServices(application, services);

        // Print the cleaned services as a space-separated string
        // This makes it easier to capture in bash
        System.out.println(String.join(" ", cleanedServices));
    }

    public static List<String> cleanServices(String application, List<String> services) {
        // Clean the services by removing unwanted characters
        List<String> cleanedServices = new ArrayList<>();
        for (String service : services) {
            String cleaned = service.replaceAll("[\\[\\],]", "");
            cleanedServices.add(cleaned);
        }

        // Handle smartfhir special case
        if (application.toLowerCase().equals("smartfhir")) {
            boolean deploymentPresent = false;
            List<String> tempServices = new ArrayList<>();

            for (String service : cleanedServices) {
                if (service.toLowerCase().equals("deployment")) {
                    deploymentPresent = true;
                } else {
                    tempServices.add(service);
                }
            }

            if (deploymentPresent) {
                cleanedServices = tempServices;
                cleanedServices.add("Main");
                cleanedServices.add("HFD");
            }
        }

        return cleanedServices;
    }
}
