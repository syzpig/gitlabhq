class DeleteDiffFilesWorker
  include ApplicationWorker

  def perform(merge_request_diff_id)
    merge_request_diff = MergeRequestDiff.find(merge_request_diff_id)

    return if merge_request_diff.without_files?

    MergeRequestDiff.transaction do
      merge_request_diff.clean!

      MergeRequestDiffFile
        .where(merge_request_diff_id: merge_request_diff.id)
        .delete_all
    end
  end
end
