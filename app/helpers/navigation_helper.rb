module NavigationHelper
  # Renders a nav link that marks itself as the current section, so the active
  # item is announced by screen readers and not only painted.
  def nav_link_to(name, path, mobile: false)
    active = current_page?(path)

    link_to name, path,
            class: nav_link_classes(active, mobile: mobile),
            aria: { current: ("page" if active) }
  end

  def nav_link_classes(active, mobile: false)
    # 44px minimum touch target on the mobile panel.
    base = mobile ? "flex items-center min-h-11 px-3 py-2 rounded-sleeve text-base" \
                  : "px-3 py-2 rounded-sleeve text-sm"

    if active
      "#{base} bg-surface-3 text-fg font-semibold"
    else
      "#{base} text-fg-muted font-medium hover:bg-surface-2 hover:text-fg"
    end
  end

  # "Last synced 3 hours ago" — the sync runs in the background now, so this is
  # the only signal that it finished.
  def last_sync_label(user)
    if user.discogs_synced?
      t("vinyl_collection.sync.last", time: time_ago_in_words(user.discogs_synced_at))
    else
      t("vinyl_collection.sync.never")
    end
  end

  def avatar_initials(user)
    user.email.to_s.strip.first(2).upcase
  end
end
