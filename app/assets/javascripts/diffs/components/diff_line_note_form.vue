<script>
import $ from 'jquery';
import { mapState, mapGetters, mapActions } from 'vuex';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import noteForm from '../../notes/components/note_form.vue';
import { getNoteFormData } from '../store/utils';
import Autosave from '../../autosave';
import { DIFF_NOTE_TYPE, NOTE_TYPE } from '../constants';

export default {
  components: {
    noteForm,
  },
  props: {
    diffFile: {
      type: Object,
      required: true,
    },
    diffLines: {
      type: Array,
      required: true,
    },
    line: {
      type: Object,
      required: true,
    },
    position: {
      type: String,
      required: false,
      default: '',
    },
    noteTargetLine: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState({
      noteableData: state => state.notes.noteableData,
      diffViewType: state => state.diffs.diffViewType,
    }),
    ...mapGetters(['isLoggedIn', 'noteableType', 'getNoteableData', 'getNotesDataByProp']),
  },
  mounted() {
    if (this.isLoggedIn) {
      const noteableData = this.getNoteableData;
      const keys = [
        NOTE_TYPE,
        this.noteableType,
        noteableData.id,
        noteableData.diff_head_sha,
        DIFF_NOTE_TYPE,
        noteableData.source_project_id,
        this.line.lineCode,
      ];

      this.autosave = new Autosave($(this.$refs.noteForm.$refs.textarea), keys);
    }
  },
  methods: {
    ...mapActions(['cancelCommentForm', 'saveNote', 'fetchDiscussions']),
    handleCancelCommentForm() {
      this.autosave.reset();
      this.cancelCommentForm({
        lineCode: this.line.lineCode,
      });
    },
    handleSaveNote(note) {
      const postData = getNoteFormData({
        note,
        noteableData: this.noteableData,
        noteableType: this.noteableType,
        noteTargetLine: this.noteTargetLine,
        diffViewType: this.diffViewType,
        diffFile: this.diffFile,
        linePosition: this.position,
      });

      this.saveNote(postData)
        .then(() => {
          const endpoint = this.getNotesDataByProp('discussionsPath');

          this.fetchDiscussions(endpoint)
            .then(() => {
              this.handleCancelCommentForm();
            })
            .catch(() => {
              createFlash(s__('MergeRequests|Updating discussions failed'));
            });
        })
        .catch(() => {
          createFlash(s__('MergeRequests|Saving the comment failed'));
        });
    },
  },
};
</script>

<template>
  <div
    class="content discussion-form discussion-form-container discussion-notes"
  >
    <note-form
      ref="noteForm"
      :is-editing="true"
      :line-code="line.lineCode"
      save-button-title="Comment"
      class="diff-comment-form"
      @cancelForm="handleCancelCommentForm"
      @handleFormUpdate="handleSaveNote"
    />
  </div>
</template>
