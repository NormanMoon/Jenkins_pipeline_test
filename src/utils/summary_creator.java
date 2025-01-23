package utils;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Iterator;

public class summary_creator {

    public static void main(String[] args) {

        String environment = args[0];
        String application = args[1];
        String image = args[2];
        String appVersion = args[3];
        String releaseType = args[4];
        // Add all inputs starting from index 5
        String other_jira_ticket_summaries = args[5];
        String[] services = Arrays.copyOfRange(args, 6, args.length);

        System.err.println("Other summaries: " + other_jira_ticket_summaries);
        // Separating services from the other summaries

        StringBuilder summaries = new StringBuilder();

        // Adding Parent ticket summary first
        if (environment.equalsIgnoreCase("Prod") || environment.equalsIgnoreCase("Prod-Beta")) {
            summaries.append(generateParentSummary(environment, releaseType, application, appVersion));
        }
        int i = 0;

        System.err.println("These are the services: " + services);
        for (String service : services) {

            if(service.equalsIgnoreCase("Other")) {
                i ++;
                summaries.append(generateOtherSummary(i, other_jira_ticket_summaries));
            } else {
                summaries.append(generateOneSummary(environment, application, image, appVersion, service));
            }
        }
        System.out.print(summaries);
    }


    public static StringBuilder generateOtherSummary(int index, String other_ticket_summaries) {
        StringBuilder summary = new StringBuilder();

        String[] parts = other_ticket_summaries.split("\\|");
        System.err.println("Parts array: " + Arrays.toString(parts));
        summary.append(parts[index]);
        summary.append("|");
        return summary;
    }

    public static StringBuilder generateOneSummary(
            String environment,
            String application,
            String image,
            String appVersion,
            String service
    ) {

        StringBuilder summary = new StringBuilder();
        if (!service.equalsIgnoreCase("other")) {
            summary.append(generateTicketSummary(environment, application, image, appVersion, service));
            summary.append("|");
        }

        return summary;
    }

    public static String generateParentSummary(
            String environment, String releaseType, String application, String appVersion
    ) {
        String parentSummary = String.format("%s: %s Release of %s %s - Parent Ticket",
                environment, releaseType, application, appVersion);
        parentSummary+="|";
        return parentSummary;
    }

    public static StringBuilder generateListOfSummaries(
            String environment,
            String application,
            String image,
            String appVersion,
            List<String> services){
        StringBuilder listOfSummaries = new StringBuilder();
        for (String service : services) {
            listOfSummaries.append(generateOneSummary(environment, application, image, appVersion, service));
        }
        return listOfSummaries;
    }

    public static String generateTicketSummary(
            String environment,
            String application,
            String image,
            String appVersion,
            String service
    ) {

        String currentDescription;
        if ("vault".equalsIgnoreCase(service)) {
            currentDescription = String.format(
                    "Deploy: %s:%s to %s",
                    image, appVersion, service
            );
        } else if ("main".equalsIgnoreCase(service) || "hfd".equalsIgnoreCase(service)) {
            currentDescription = String.format(
                    "Deploy %s:%s for %s to %s",
                    image, appVersion, application, service
            );
        } else if ("deployment".equalsIgnoreCase(service)) {
            currentDescription = String.format(
                    "%s: Deploy %s:%s for %s",
                    environment, image, appVersion, application
            );
        } else {
            currentDescription = String.format(
                    "%s: Change %s config for %s in %s",
                    environment, service, application, image
            );
        }
        return currentDescription;

    }


}


