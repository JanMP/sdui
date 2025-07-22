import {Jobs} from 'meteor/msavin:sjobs'
import {updateFeeds} from './ResearchedArticles.coffee'
import {DateTime} from 'luxon'

export registerJobs = ({sourceName}) ->
  Jobs.register
    "#{sourceName}.updateFeeds": ->
      console.log "#{new Date()} - #{sourceName} - Updating Rss feeds"
      updateFeeds()
      .then =>
        console.log "#{sourceName} Successfully updated Rss feeds"
        offset = DateTime.local().setZone('Europe/Berlin').offset / 60
        currentHour = new Date().getUTCHours()
        [morgen, mittag, abend] = [6, 12, 19].map (hour) -> hour - offset
        console.log {currentHour, morgen, mittag, abend}
        scedule =
          switch
            when currentHour < morgen
              on:
                hour: morgen
                minute: 0
            when currentHour < mittag
              on:
                hour: mittag
                minute: 0
            when currentHour < abend
              on:
                hour: abend
                minute: 30
            else
              in: days: 1
              on:
                hour: morgen
                minute: 0
        console.log {scedule}
        @replicate scedule
        @remove()
      .catch (error) =>
        console.error error.message
        @reschedule in: hours: 2